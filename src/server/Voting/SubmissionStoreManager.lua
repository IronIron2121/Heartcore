--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Caching variables
local pendingUpdates = {}
local lastFlush = tick()
local FLUSH_INTERVAL = 60 
local MAX_PENDING_UPDATES = 50
local isFlushingInProgress = false

local SubmissionStoreManager = {}

local function getCurrentMemoryStoreIndex(): number
    -- TODO: Implement store index tracking
    return 1
end

function SubmissionStoreManager.getCurrentMemoryStoreName(): string?
    local currentPrefix = GameTimer.getCurrentPhasePrefix()
    local currentIndex = getCurrentMemoryStoreIndex()
    
    if currentPrefix then
        return currentPrefix .. Constants.SUBMISSION_MEMORYSTORE_NAME .. currentIndex
    else
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
                os.time()
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
    task.spawn(function()
        while true do
            task.wait(FLUSH_INTERVAL)
            warn("Flushing submissions!")
            if not isFlushingInProgress and next(pendingUpdates) then
                SubmissionStoreManager.flushPendingUpdates()
            end
        end
    end)
end

function SubmissionStoreManager:AddEntryToCache(player: Player, serialisedHumanoidDescription: {})
    pendingUpdates[tostring(player.UserId)] = {
        userId = player.UserId,
        humanoidDescription = serialisedHumanoidDescription
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

function SubmissionStoreManager:AddEntryToStore(player: Player, serialisedHumanoidDescription: {}): ()
    local currentSubmissionsMemoryStore = self.getCurrentSubmissionMemoryStore()
    if not currentSubmissionsMemoryStore then 
        warn("Failed to get submissions memory store") 
        SubmissionResultRE:FireClient(player, {
            ok = false,
            msg = "Server error. Please try again."
        })
        return 
    end

    local success = callWithRetry(function()
        return currentSubmissionsMemoryStore:SetAsync(
            tostring(player.UserId),
            {
                userId = player.UserId,
                humanoidDescription = serialisedHumanoidDescription,
            },
            Constants.MEMORYSTORE_STORE_DURATION,
            os.time()
        )
    end, 5)

    if success then
        print("Successfully submitted outfit for player:", player.Name)
        SubmissionResultRE:FireClient(player, {
            ok = true,
            msg = "Outfit submitted successfully!"
        })
    else
        warn("Failed to submit outfit for player:", player.Name)
        SubmissionResultRE:FireClient(player, {
            ok = false,
            msg = "Failed to submit outfit. Please try again."
        })
    end
end

return SubmissionStoreManager