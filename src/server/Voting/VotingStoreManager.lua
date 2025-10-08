--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local votingZone = workspace:WaitForChild("votingZone")

-- Modules
local CacheBasedBalancedSelector = require(Voting:WaitForChild("CacheBasedBalancedSelector"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Remotes / Bindables
local ThemeChangedRemote = RemotesFolder:WaitForChild("ThemeChanged")

-- Instances
local BillboardHolder = votingZone:WaitForChild("BillboardHolder")
local ThemeNameBillboard = BillboardHolder:WaitForChild("ThemeNameBillboard")
local ThemeNameTextLabel = ThemeNameBillboard:WaitForChild("TextLabel")

local VotingStoreManager = {}

-- Theme configuration
local AVAILABLE_THEMES = {
    "Cyberpunk Streetwear",
    "Medieval Knight", 
    "Beach Party",
    "Winter Wonderland",
    "Space Explorer",
    "Royal Ball",
    "Sports Day"
}

-- Current theme and voting phase
local currentTheme = nil
local activeVotingPhasePrefix = nil -- Which day's submissions we're voting on

-- Active store tracking
local currentActiveStore = nil -- The ONE store this server is currently working with
local currentActiveStoreName = "" -- Name of that store
local STORE_ROTATION_INTERVAL = 600 -- 10 minutes

-- Caching variables
local pendingUpdates = {} -- {entryKey = {votes = 0, views = 0}}
local lastFlush = tick()
local FLUSH_INTERVAL = 60 
local MAX_PENDING_UPDATES = 50
local isFlushingInProgress = false

-- Public cache for current voting entries (from the current active store)
local publicCache = {} -- {entryKey = {userId, description, votes, views}}
local isCacheUpdating = false

-- Balanced selector instance
local balancedSelector = CacheBasedBalancedSelector.new()

-- Theme Management Functions
local function getCurrentUniversalTime()
    return DateTime.now().UnixTimestamp
end

local function pickRandomTheme(): string
    return AVAILABLE_THEMES[math.random(1, #AVAILABLE_THEMES)]
end

local function createNewTheme(): {}
    return {
        Theme = pickRandomTheme(),
        TimeChanged = getCurrentUniversalTime(),
        PhasePrefix = GameTimer.getCurrentPhasePrefix()
    }
end

function VotingStoreManager.getCurrentTheme(): {}?
    return currentTheme
end

function VotingStoreManager.getThemeName(): string
    return currentTheme and currentTheme.Theme or "Loading..."
end

function VotingStoreManager.getThemeTimeChanged(): number?
    return currentTheme and currentTheme.TimeChanged or nil
end

function VotingStoreManager.getAvailableThemes(): {string}
    return AVAILABLE_THEMES
end

local function updateThemeBillboardText()
    ThemeNameTextLabel.Text = VotingStoreManager.getThemeName()
end

local function getThemeMemoryStore()
    local success, memoryStore = callWithRetry(
        function()
            return MemoryStoreService:GetSortedMap(Constants.THEME_MEMORYSTORE_NAME)
        end,
        3
    )
    return success and memoryStore or nil
end

local function updateTheme(themeMemoryStore: MemoryStoreHashMap?): boolean
    print("Updating to new theme...")
    local newTheme = createNewTheme()
    
    local memoryStore = themeMemoryStore or getThemeMemoryStore()
    if not memoryStore then
        warn("Failed to get theme memory store for update")
        return false
    end
    
    local success, result = callWithRetry(
        function()
            return memoryStore:SetAsync(
                Constants.CURRENT_THEME_KEY,
                newTheme,
                Constants.MEMORYSTORE_STORE_DURATION
            )
        end,
        5
    )

    if success then
        currentTheme = newTheme
        ThemeChangedRemote:FireAllClients(newTheme)
        updateThemeBillboardText()
        print("Updated to new theme:", newTheme.Theme)
        return true
    else
        warn("Failed to update theme:", result)
        return false
    end
end

local function initialiseTheme(): boolean
    warn("Initialising theme...")
    local themeMemoryStore = getThemeMemoryStore()
    if not themeMemoryStore then
        warn("Failed to get theme memory store")
        return false
    end

    local success, currentThemeData = callWithRetry(
        function()
            return themeMemoryStore:GetAsync(Constants.CURRENT_THEME_KEY)
        end, 
        5
    )

    if not success then
        warn("Failed to retrieve theme data:", currentThemeData)
        return false
    end

    if not currentThemeData or not currentThemeData.Theme then
        warn("No current theme found, creating new one...")
        local updateSuccess = updateTheme(themeMemoryStore)
        return updateSuccess
    else
        currentTheme = currentThemeData
        ThemeChangedRemote:FireAllClients(currentThemeData)
        updateThemeBillboardText()
        print("Loaded existing theme:", currentThemeData.Theme)
        return true
    end
end

-- Voting Phase Management
function VotingStoreManager.setActiveVotingPhase(phasePrefix: string)
    print("Setting active voting phase to:", phasePrefix)
    activeVotingPhasePrefix = phasePrefix
    
    -- Pick a random store and load it
    VotingStoreManager.rotateStore()
end

function VotingStoreManager.getActiveVotingPhase(): string?
    return activeVotingPhasePrefix
end

-- Get all submission store names for a given phase
local function getSubmissionStoreNames(phasePrefix: string): {string}
    local storeNames = {}
    
    -- Get the info store to find out how many submission stores exist
    local infoStoreName = phasePrefix .. Constants.SUBMISSION_INFO_MEMORYSTORE_NAME
    local success, infoStore = callWithRetry(function()
        return MemoryStoreService:GetSortedMap(infoStoreName)
    end, 3)
    
    if not success or not infoStore then
        warn("Could not get submission info store for phase:", phasePrefix)
        return storeNames
    end
    
    local infoSuccess, info = callWithRetry(function()
        return infoStore:GetAsync(Constants.CURRENT_SUBMISSION_INFO_KEY)
    end, 3)
    
    if not infoSuccess or not info then
        warn("Could not get submission info for phase:", phasePrefix)
        return storeNames
    end
    
    -- Generate store names from 1 to currentStoreNumber
    local maxStoreNumber = info.currentStoreNumber or 1
    for i = 1, maxStoreNumber do
        local storeName = phasePrefix .. Constants.SUBMISSION_MEMORYSTORE_NAME .. i
        table.insert(storeNames, storeName)
    end
    
    print("Found", #storeNames, "submission stores for phase:", phasePrefix)
    return storeNames
end

-- Read all entries from a submission store
local function getAllEntriesFromSubmissionStore(storeName: string): {[string]: any}
    local entries = {}
    
    local success, store = callWithRetry(function()
        return MemoryStoreService:GetSortedMap(storeName)
    end, 3)
    
    if not success or not store then
        warn("Failed to get submission store:", storeName)
        return entries
    end
    
    local rangeSuccess, items = callWithRetry(function()
        return store:GetRangeAsync(Enum.SortDirection.Ascending, 200)
    end, 3)
    
    if not rangeSuccess or not items then
        warn("Failed to get range from store:", storeName)
        return entries
    end
    
    for _, item in ipairs(items) do
        entries[item.key] = item.value
    end
    
    return entries
end

-- Pick a random store and load it into cache
function VotingStoreManager.rotateStore()
    if not activeVotingPhasePrefix then
        warn("No active voting phase set, cannot rotate store")
        return
    end
    
    -- Flush any pending updates to the current store before rotating
    if currentActiveStore and next(pendingUpdates) then
        VotingStoreManager.flushPendingUpdates()
    end
    
    print("Rotating to a new submission store...")
    
    -- Get all available stores for this phase
    local storeNames = getSubmissionStoreNames(activeVotingPhasePrefix)
    
    if #storeNames == 0 then
        warn("No submission stores available for phase:", activeVotingPhasePrefix)
        return
    end
    
    -- Pick a random store
    local randomIndex = math.random(1, #storeNames)
    local selectedStoreName = storeNames[randomIndex]
    
    print("Selected store:", selectedStoreName)
    
    -- Get the store
    local success, store = callWithRetry(function()
        return MemoryStoreService:GetSortedMap(selectedStoreName)
    end, 3)
    
    if not success or not store then
        warn("Failed to get selected store:", selectedStoreName)
        return
    end
    
    -- Update active store references
    currentActiveStore = store
    currentActiveStoreName = selectedStoreName
    
    -- Load entries from this store
    VotingStoreManager.loadCacheFromCurrentStore()
end

-- Load cache from the current active store
function VotingStoreManager.loadCacheFromCurrentStore()
    if not currentActiveStore or not currentActiveStoreName then
        warn("No active store set")
        return
    end
    
    if isCacheUpdating then
        warn("Cache update already in progress")
        return
    end
    
    isCacheUpdating = true
    print("Loading cache from store:", currentActiveStoreName)
    
    local entries = getAllEntriesFromSubmissionStore(currentActiveStoreName)
    
    local newCache = {}
    local totalEntries = 0
    
    for entryKey, entryData in pairs(entries) do
        totalEntries += 1
        
        newCache[entryKey] = {
            userId = entryData.userId,
            humanoidDescription = entryData.humanoidDescription,
            theme = currentTheme and currentTheme.Theme or "Unknown",
            votes = entryData.votes or 0,
            views = entryData.views or 0
        }
    end
    
    -- Update the public cache
    publicCache = newCache
    
    print("Loaded", totalEntries, "entries from", currentActiveStoreName)
    
    -- Rebuild selection buckets
    local rebuildSuccess = balancedSelector:onCacheUpdated(publicCache)
    if rebuildSuccess then
        print("Selection buckets rebuilt successfully")
    else
        warn("Failed to rebuild selection buckets")
    end
    
    isCacheUpdating = false
end

function VotingStoreManager.initialise(): ()
    local themeSuccess = initialiseTheme()
    if not themeSuccess then
        error("Failed to initialise theme system")
    end
    
    -- Set active voting phase to previous day (if it exists)
    local previousPrefix = GameTimer.getPreviousPhasePrefix()
    if previousPrefix then
        VotingStoreManager.setActiveVotingPhase(previousPrefix)
    else
        warn("No previous phase available for voting yet")
    end
    
    -- Start periodic systems
    VotingStoreManager.startPeriodicFlush()
    VotingStoreManager.startStoreRotation()
end

function VotingStoreManager.addViews(entryKey: string, viewAmount: number): ()
    if not currentActiveStore then
        warn("No active store set")
        return
    end
    
    -- initialise entry in pending updates if it doesn't exist
    if not pendingUpdates[entryKey] then
        pendingUpdates[entryKey] = {votes = 0, views = 0}
    end
    
    -- Add to pending updates
    pendingUpdates[entryKey].views += viewAmount
    
    -- Also update the public cache immediately for real-time UI updates
    if publicCache[entryKey] then 
        publicCache[entryKey].views += viewAmount
    end
    
    -- Check if we should flush
    local pendingCount = 0
    for _ in pairs(pendingUpdates) do
        pendingCount += 1
    end
    
    local shouldFlushByTime = tick() - lastFlush > FLUSH_INTERVAL
    local shouldFlushByCount = pendingCount >= MAX_PENDING_UPDATES
    
    if (shouldFlushByTime or shouldFlushByCount) and not isFlushingInProgress then
        VotingStoreManager.flushPendingUpdates()
    end
end

function VotingStoreManager.addVotes(entryKey: string, voteAmount: number): ()
    if not currentActiveStore then
        warn("No active store set")
        return
    end
    
    -- initialise entry in pending updates if it doesn't exist
    if not pendingUpdates[entryKey] then
        pendingUpdates[entryKey] = {votes = 0, views = 0}
    end
    
    -- Add to pending updates
    pendingUpdates[entryKey].votes += voteAmount
    
    -- Also update the public cache immediately for real-time UI updates
    if publicCache[entryKey] then
        publicCache[entryKey].votes += voteAmount
    end
    
    -- Check if we should flush
    local pendingCount = 0
    for _ in pairs(pendingUpdates) do
        pendingCount += 1
    end
    
    local shouldFlushByTime = tick() - lastFlush > FLUSH_INTERVAL
    local shouldFlushByCount = pendingCount >= MAX_PENDING_UPDATES
    
    if (shouldFlushByTime or shouldFlushByCount) and not isFlushingInProgress then
        VotingStoreManager.flushPendingUpdates()
    end
end

function VotingStoreManager.flushPendingUpdates(): ()
    if isFlushingInProgress then
        return 
    end
    
    if next(pendingUpdates) == nil then
        return 
    end
    
    if not currentActiveStore or not currentActiveStoreName then
        warn("No active store, cannot flush updates")
        return
    end
    
    isFlushingInProgress = true
    
    local updatesToFlush = {}
    for entryKey, updates in pairs(pendingUpdates) do
        updatesToFlush[entryKey] = {
            votes = updates.votes,
            views = updates.views
        }
    end
    pendingUpdates = {}
    
    print("Flushing", #updatesToFlush, "updates to store:", currentActiveStoreName)
    
    -- Update entries in the current active store
    for entryKey, updates in pairs(updatesToFlush) do
        if updates.votes ~= 0 or updates.views ~= 0 then
            local success = callWithRetry(function()
                return currentActiveStore:UpdateAsync(entryKey, function(oldValue)
                    if oldValue then
                        oldValue.votes = (oldValue.votes or 0) + updates.votes
                        oldValue.views = (oldValue.views or 0) + updates.views
                        return oldValue
                    else
                        warn("Entry not found during flush:", entryKey)
                        return nil
                    end
                end, Constants.MEMORYSTORE_STORE_DURATION)
            end, 3)
            
            if not success then
                warn("Failed to flush updates for entry:", entryKey)
            end
        end
    end
    
    lastFlush = tick()
    isFlushingInProgress = false
    print("Flush completed")
end

function VotingStoreManager.startPeriodicFlush(): ()
    print("Starting periodic flush!")
    
    task.spawn(function()
        while true do
            task.wait(FLUSH_INTERVAL)
            if not isFlushingInProgress and next(pendingUpdates) then
                VotingStoreManager.flushPendingUpdates()
            end
        end
    end)
end

function VotingStoreManager.startStoreRotation(): ()
    print("Starting store rotation (every", STORE_ROTATION_INTERVAL, "seconds)")
    
    task.spawn(function()
        while true do
            task.wait(STORE_ROTATION_INTERVAL)
            VotingStoreManager.rotateStore()
        end
    end)
end

-- Get the public cache
function VotingStoreManager.getPublicCache(): {}
    return publicCache
end

-- Get a specific entry from the public cache
function VotingStoreManager.getCachedEntry(entryKey: string): {}?
    local cachedEntry = publicCache[entryKey]
    if not cachedEntry then
        return nil
    end
    
    -- Create a copy and add any pending updates
    local entry = {
        userId = cachedEntry.userId,
        humanoidDescription = cachedEntry.humanoidDescription,
        theme = cachedEntry.theme,
        votes = cachedEntry.votes,
        views = cachedEntry.views
    }
    
    -- Add pending updates if they exist
    if pendingUpdates[entryKey] then
        entry.votes += pendingUpdates[entryKey].votes
        entry.views += pendingUpdates[entryKey].views
    end
    
    return entry
end

-- Get a balanced outfit selection
function VotingStoreManager.getBalancedOutfit(): string?
    return balancedSelector:selectOutfit()
end

function VotingStoreManager.forceFlush(): ()
    VotingStoreManager.flushPendingUpdates()
end

function VotingStoreManager.getPendingUpdates(): {}
    return pendingUpdates
end

-- Phase transition handler
function VotingStoreManager.onPhaseTransition()
    print("VotingStoreManager handling phase transition...")
    
    -- Flush any pending updates before switching phases
    if next(pendingUpdates) then
        VotingStoreManager.flushPendingUpdates()
    end
    
    -- Update theme for new day
    local themeSuccess = updateTheme()
    if not themeSuccess then
        warn("Failed to update theme during phase transition")
    end
    
    -- Set voting to yesterday's submissions
    local previousPrefix = GameTimer.getPreviousPhasePrefix()
    if previousPrefix then
        VotingStoreManager.setActiveVotingPhase(previousPrefix)
    else
        warn("No previous phase available for voting")
    end
end

return VotingStoreManager