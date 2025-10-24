--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local centralPond = workspace:WaitForChild("centralPond")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))
local ThemeManager = require(Voting:WaitForChild("ThemeManager"))

-- Instances
local centralPondModel = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = centralPondModel:WaitForChild("SubmissionBillboardHolder")
local SubmissionThemeBillboard = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame = SubmissionThemeBillboard:WaitForChild("Frame")
local SubmissionThemeTextLabel = Frame:WaitForChild("ThemeLabel")

-- Caching variables
local pendingUpdates = {}
local lastFlush = tick()
local FLUSH_INTERVAL = 60 
local MAX_PENDING_UPDATES = 50
local isFlushingInProgress = false

-- Lock configuration
local ROLLOVER_LOCK_DURATION = 120 -- 2 minutes for crash recovery
local ROLLOVER_LOCK_KEY = "submission_rollover_lock"

-- Constants
local REUPDATE_THEME_WAIT_TIME = 10

local SubmissionStoreManager = {}

local function updateSubmissionThemeBillboard()
    local themeName = ThemeManager.getCurrentThemeName()
    SubmissionThemeTextLabel.Text = "THEME: " .. themeName
    warn("Updating theme", SubmissionThemeTextLabel.Text)
    warn(themeName)
    if themeName == "Loading..." then
        task.wait(REUPDATE_THEME_WAIT_TIME)
        task.spawn(function()
            updateSubmissionThemeBillboard()
        end)
    end
end

local function getRolloverLockStore()
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    if not currentPrefix then 
        return nil
    end
    
    local success, lockStore = callWithRetry(function()
        return MemoryStoreService:GetSortedMap(currentPrefix .. "_SubmissionRolloverLocks")
    end, 3)
    
    if success then
        return lockStore
    end
    return nil
end

local function acquireRolloverLock(): boolean
    local lockStore = getRolloverLockStore()
    if not lockStore then
        warn("Failed to get rollover lock store")
        return false
    end
    
    local success, result = callWithRetry(function()
        return lockStore:SetAsync(
            ROLLOVER_LOCK_KEY,
            game.JobId, -- Store which server has the lock
            ROLLOVER_LOCK_DURATION,
            DateTime.now().UnixTimestamp
        )
    end, 3)
    
    return success == true
end

local function releaseRolloverLock(): ()
    local lockStore = getRolloverLockStore()
    if not lockStore then
        return
    end
    
    callWithRetry(function()
        return lockStore:RemoveAsync(ROLLOVER_LOCK_KEY)
    end, 3)
end

local function isRolloverLockActive(): boolean
    local lockStore = getRolloverLockStore()
    if not lockStore then
        return false
    end
    
    local success, lockValue = callWithRetry(function()
        return lockStore:GetAsync(ROLLOVER_LOCK_KEY)
    end, 3)
    
    -- Lock exists if we successfully got a non-nil value
    return success and lockValue ~= nil
end

local function getCurrentMemoryStoreIndex(): number?
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    if not currentPrefix then 
        warn("No current prefix!")
        return nil
    end

    local success, result = callWithRetry(
        function()
            return MemoryStoreService:GetSortedMap(currentPrefix .. Constants.SUBMISSION_INFO_MEMORYSTORE_NAME)
        end
    )

    if not success or not result then
        warn("Failed to get info store!")
        return nil
    end

    local infoSuccess, info = callWithRetry(function()
        return result:GetAsync(Constants.CURRENT_SUBMISSION_INFO_KEY)
    end, 3)
    
    if infoSuccess and info then
        return info.currentStoreNumber
    end
    
    if infoSuccess and not info then
        -- Info store exists but no data - initialise it
        warn("No submission info found, initializing...")
        local initSuccess = SubmissionStoreManager.initialiseNewSubmissionStore()
        
        if not initSuccess then
            warn("Failed to initialise submission store!")
            return nil
        end
        
        -- Return default store number after initialization
        return 1
    end
    
    warn("Failed to get submission info:", infoSuccess, info)
    return nil
end

function SubmissionStoreManager.getCurrentInfoStoreName(): string?
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    if not currentPrefix then 
        warn("No current prefix!")
        return nil
    end
    
    return currentPrefix .. Constants.SUBMISSION_INFO_MEMORYSTORE_NAME
end

function SubmissionStoreManager.initialiseNewSubmissionStore()
    warn("Initialising new submission store!")
    
    -- Get current theme from ThemeManager
    local currentTheme = ThemeManager.getCurrentTheme()
    local themeName = currentTheme and currentTheme.theme or "Unknown"
    
    local submissionsStoreInfo = {
        phaseDate = GameTimer.getCurrentPhasePrefix(),
        currentStoreNumber = 1, 
        storeSubmissionCount = 0,
        lastUpdated = DateTime.now().UnixTimestamp,
        theme = themeName
    }

    local currentInfoStoreName = SubmissionStoreManager.getCurrentInfoStoreName()

    local success, submissionInfo = callWithRetry(
        function()
            return MemoryStoreService:GetSortedMap(currentInfoStoreName)
        end
    )

    if not submissionInfo then
        warn("No submission info!")
        return false
    end

    local setSuccess = callWithRetry(
        function()
            return submissionInfo:SetAsync(Constants.CURRENT_SUBMISSION_INFO_KEY, submissionsStoreInfo, Constants.MEMORYSTORE_STORE_DURATION)
        end
    )

    if setSuccess then
       warn("Just ++ set current submission info with theme:", themeName)
       print(submissionInfo:GetAsync(Constants.CURRENT_SUBMISSION_INFO_KEY)) 
    else
        warn("Failed to set submission info!")
    end

    return setSuccess
end

function SubmissionStoreManager.incrementIndex(): boolean
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    if not currentPrefix then 
        warn("No current prefix!")
        return false
    end

    -- Acquire lock before incrementing
    local gotLock = acquireRolloverLock()
    if not gotLock then
        warn("Failed to acquire rollover lock - another server is handling rollover")
        return false
    end

    -- Get current theme from ThemeManager
    local currentTheme = ThemeManager.getCurrentTheme()
    local themeName = currentTheme and currentTheme.theme or "Unknown"

    local success, result = callWithRetry(
        function()
            return MemoryStoreService:GetSortedMap(currentPrefix .. Constants.SUBMISSION_INFO_MEMORYSTORE_NAME)
        end
    )

    if not result then 
        releaseRolloverLock()
        return false
    end

    if success and result then
        local infoSuccess, info = callWithRetry(function()
            return result:UpdateAsync(Constants.CURRENT_SUBMISSION_INFO_KEY, function(infoTable)
                infoTable = infoTable or {
                    phaseDate = GameTimer.getCurrentPhasePrefix(),
                    currentStoreNumber = 1,
                    storeSubmissionCount = 0,
                    lastUpdated = DateTime.now().UnixTimestamp,
                    theme = themeName
                }

                infoTable.currentStoreNumber = tonumber(infoTable.currentStoreNumber) + 1
                infoTable.storeSubmissionCount = 0
                infoTable.lastUpdated = DateTime.now().UnixTimestamp
                -- Keep the same theme during rollover
                infoTable.theme = themeName

                return infoTable
            end)
        end, 3)
        
        releaseRolloverLock()
        
        if infoSuccess and info then
            print("Successfully rolled over to submission store #" .. info.currentStoreNumber .. " with theme:", themeName)
            return true
        end
    end
    
    releaseRolloverLock()
    return false
end

function SubmissionStoreManager.getCurrentMemoryStoreName(): string?
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    local currentIndex = getCurrentMemoryStoreIndex()
    
    if currentPrefix and currentIndex then
        return currentPrefix .. Constants.SUBMISSION_MEMORYSTORE_NAME .. currentIndex
    else
        warn("Failed to get name!", currentPrefix, currentIndex)
        return nil
    end
end

function SubmissionStoreManager.getPreviousMemoryStoreName(): string?
    local previousPrefix = GameTimer.getPreviousPhasePrefix()
    if previousPrefix then
        return previousPrefix .. Constants.SUBMISSION_MEMORYSTORE_NAME
    else
        return nil
    end
end

function SubmissionStoreManager.getCurrentSubmissionMemoryStore()
    local currentStoreName = SubmissionStoreManager.getCurrentMemoryStoreName()
    if not currentStoreName then
        warn("Memory store not ready!") 
        return nil 
    end

    local success, result = callWithRetry(function()
        return MemoryStoreService:GetSortedMap(currentStoreName)
    end, 3)
    
    if success then 
        return result 
    else 
        warn("Failed to get current memorystore:", result)
        return nil
    end
end

function SubmissionStoreManager.getPreviousSubmissionMemoryStore()
    local previousStoreName = SubmissionStoreManager.getPreviousMemoryStoreName()
    if not previousStoreName then
        warn("No previous store name available")
        return nil
    end
    
    local success, result = callWithRetry(function()
        return MemoryStoreService:GetSortedMap(previousStoreName)
    end, 3)
    
    if success then 
        return result 
    else 
        warn("Failed to get previous memorystore:", result)
        return nil
    end
end

local function getAllSortedMapEntries(sortedMap): {[string]: any}
    local allEntries = {}
    
    local success, items = callWithRetry(function()
        return sortedMap:GetRangeAsync(Enum.SortDirection.Ascending, 100)
    end, 3)
    
    if not success or not items then
        warn("Failed to get range from sorted map")
        return allEntries
    end
    
    for _, item in ipairs(items) do
        allEntries[item.key] = item.value
    end
    
    return allEntries
end

function SubmissionStoreManager:GetEntries(): {[string]: any}
    local currentStore = self.getCurrentSubmissionMemoryStore()
    
    if not currentStore then
        warn("Could not get current submissions store")
        return {}
    end
    
    return getAllSortedMapEntries(currentStore)
end

function SubmissionStoreManager:GetPreviousPhaseEntries(): {[string]: any}
    local previousStore = self.getPreviousSubmissionMemoryStore()
    
    if not previousStore then
        warn("Could not get previous submissions store")
        return {}
    end
    
    return getAllSortedMapEntries(previousStore)
end

function SubmissionStoreManager.flushPendingUpdates(): ()
    if isFlushingInProgress then
        return 
    end
    
    if next(pendingUpdates) == nil then
        return 
    end
    
    isFlushingInProgress = true
    
    local currentMemoryStore = SubmissionStoreManager.getCurrentSubmissionMemoryStore()
    if not currentMemoryStore then
        warn("Cannot flush: no current memory store")
        isFlushingInProgress = false
        return
    end
    
    local updatesToFlush = {}
    for entryKey, updates in pairs(pendingUpdates) do
        updatesToFlush[entryKey] = {
            userId = updates.userId,
            humanoidDescription = updates.humanoidDescription,
        }
    end
    
    pendingUpdates = {}
    
    print("Flushing", #updatesToFlush, "pending submissions to MemoryStore")
    
    for entryKey, updates in pairs(updatesToFlush) do
        local success = callWithRetry(function()
            return currentMemoryStore:SetAsync(
                entryKey, 
                updates, 
                Constants.MEMORYSTORE_STORE_DURATION, 
                DateTime.now().UnixTimestamp
            )
        end, 3)
        
        if not success then
            warn("Failed to flush submission for entry:", entryKey)
        end
    end
    
    lastFlush = tick()
    isFlushingInProgress = false
end

function SubmissionStoreManager.startPeriodicFlush(): ()
    warn("starting flush for sub store!")
    task.spawn(function()
        while true do
            task.wait(FLUSH_INTERVAL)
            if not isFlushingInProgress and next(pendingUpdates) then
                SubmissionStoreManager.flushPendingUpdates()
            end
        end
    end)
    warn("Done!")
end

function SubmissionStoreManager.initialise(): () 
    SubmissionStoreManager.startPeriodicFlush()
    -- Update billboard with current theme on initialization
    updateSubmissionThemeBillboard()
end

function SubmissionStoreManager:AddEntryToCache(player: Player, serialisedHumanoidDescription: {})
    pendingUpdates[tostring(player.UserId)] = {
        userId = player.UserId,
        humanoidDescription = serialisedHumanoidDescription,
        votes = 0,
        views = 0,
    }
    
    -- Check if we should flush
    local pendingCount = 0
    for _ in pairs(pendingUpdates) do
        pendingCount += 1
    end
    
    local shouldFlushByTime = tick() - lastFlush > FLUSH_INTERVAL
    local shouldFlushByCount = pendingCount >= MAX_PENDING_UPDATES
    
    if (shouldFlushByTime or shouldFlushByCount) and not isFlushingInProgress then
        SubmissionStoreManager.flushPendingUpdates()
    end
end

function SubmissionStoreManager:AddEntryToStore(player: Player, serialisedHumanoidDescription: {}): boolean
    -- Check if rollover is happening
    if isRolloverLockActive() then
        print("Rollover in progress for player " .. player.Name .. ", adding to cache instead")
        SubmissionStoreManager:AddEntryToCache(player, serialisedHumanoidDescription)
        SubmissionResultRE:FireClient(player, {
            ok = false,
            msg = "Outfit failed to submit! 2"
        })
        return false
    end
    
    local currentSubmissionsMemoryStore = self.getCurrentSubmissionMemoryStore()
    if not currentSubmissionsMemoryStore then 
        warn("Failed to get submissions memory store") 
        SubmissionResultRE:FireClient(player, {
            ok = false,
            msg = "Server error. Please try again."
        })
        return false
    end

    local success = callWithRetry(function()
        return currentSubmissionsMemoryStore:SetAsync(
            tostring(player.UserId),
            {
                userId = player.UserId,
                humanoidDescription = serialisedHumanoidDescription,
                votes = 0,
                views = 0,
            },
            Constants.MEMORYSTORE_STORE_DURATION,
            DateTime.now().UnixTimestamp
        )
    end, 3)

    if success then
        print("Successfully submitted outfit for player:", player.Name)
        SubmissionResultRE:FireClient(player, {
            ok = true,
            msg = "Outfit submitted successfully! 2"
        })
        
        -- Check if we need to rollover to a new store
        local currentSize = currentSubmissionsMemoryStore:GetSizeAsync()
        if currentSize >= Constants.MAX_SUBMISSIONS_PER_MEMORYSTORE then
            print("Store full (" .. currentSize .. " entries), attempting rollover...")
            SubmissionStoreManager.incrementIndex()
        end
        return true
    else
        warn("Failed to submit outfit for player:", player.Name)
        SubmissionResultRE:FireClient(player, {
            ok = false,
            msg = "Failed to submit outfit. Please try again."
        })
        return false
    end
end

-- Phase transition handler - called when the day changes
function SubmissionStoreManager.onPhaseTransition()
    print("SubmissionStoreManager handling phase transition...")
    
    -- Update the submission billboard with new theme
    updateSubmissionThemeBillboard() 
    
    print("Submission billboard updated with new theme")
end

-- Phase transition handler - called when the day changes
function SubmissionStoreManager.onThemeTransition()
    warn("Updating after theme transition")
    -- Update the submission billboard with new theme
    updateSubmissionThemeBillboard() 
end

return SubmissionStoreManager