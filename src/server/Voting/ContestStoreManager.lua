--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Modules
local printAllHashMapPages = require(Utility:WaitForChild("printAllHashMapStorePages"))
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

local ContestStoreManager = {}

-- Caching variables
local pendingUpdates = {} -- {entryKey = {votes = 0, views = 0}}
local lastFlush = tick()
local FLUSH_INTERVAL = 30 -- seconds
local MAX_PENDING_UPDATES = 50 -- flush if we hit this many pending updates
local isFlushingInProgress = false

-- Public cache for current contest entries
local publicCache = {} -- {entryKey = {id, description, votes, views}}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 300 -- 5 minutes in seconds
local isCacheUpdating = false

function ContestStoreManager.getCurrentMemoryStoreName(): string
    return GameTimer.getTodayDateTimePrefix() .. Constants.CONTEST_MEMORYSTORE_NAME
end

function ContestStoreManager.initialiseNewContest(): boolean
    warn("Initialising new contest")
    local contestStoreName = ContestStoreManager.getCurrentMemoryStoreName()
    local currentMemoryStore = MemoryStoreService:GetHashMap(contestStoreName)

    local allSubmissions = SubmissionStoreManager:GetPreviousPhaseEntries()
    print("Found submissions for contest:", allSubmissions)

    if not allSubmissions or next(allSubmissions) == nil then
        warn("No submissions found to initialize contest with")
        return false
    end

    local successCount = 0
    local totalCount = 0

    for key, entry in pairs(allSubmissions) do
        totalCount = totalCount + 1
        warn("Processing entry for contest:", key)
        
        local contestSubmission = {
            userId = entry.userId,
            playerName = entry.playerName,
            humanoidDescription = entry.humanoidDescription,
            submissionTime = entry.submissionTime,
            votes = 0,
            views = 0
        }
         
        -- Add the contest submission at the key of the corresponding submission
        local success = callWithRetry(function()
            return currentMemoryStore:SetAsync(key, contestSubmission, 259200) -- 3 day expiration
        end, 3)
        
        if success then
            successCount = successCount + 1
            print("Added contest entry for:", key)
        else
            warn("Failed to add contest entry for:", key)
        end
    end
    
    print(string.format("Contest initialization complete: %d/%d entries added successfully", successCount, totalCount))
    
    if successCount > 0 then
        -- Start the periodic flush and cache updates after initialization
        ContestStoreManager.startPeriodicFlush()
        ContestStoreManager.updatePublicCache() -- Initial cache population
        return true
    else
        return false
    end
end

function ContestStoreManager.addViews(entryKey: string, viewAmount: number): ()
    -- Initialize entry in pending updates if it doesn't exist
    if not pendingUpdates[entryKey] then
        pendingUpdates[entryKey] = {votes = 0, views = 0}
    end
    
    -- Add to pending updates
    pendingUpdates[entryKey].views += viewAmount
    
    -- Check if we should flush (either by time or count)
    local pendingCount = 0
    for _ in pairs(pendingUpdates) do
        pendingCount += 1
    end
    
    local shouldFlushByTime = tick() - lastFlush > FLUSH_INTERVAL
    local shouldFlushByCount = pendingCount >= MAX_PENDING_UPDATES
    
    if (shouldFlushByTime or shouldFlushByCount) and not isFlushingInProgress then
        ContestStoreManager.flushPendingUpdates()
    end
end

function ContestStoreManager.addVotes(entryKey: string, voteAmount: number): ()
    -- Initialize entry in pending updates if it doesn't exist
    if not pendingUpdates[entryKey] then
        pendingUpdates[entryKey] = {votes = 0, views = 0}
    end
    
    -- Add to pending updates
    pendingUpdates[entryKey].votes += voteAmount
    
    -- Check if we should flush (either by time or count)
    local pendingCount = 0
    for _ in pairs(pendingUpdates) do
        pendingCount += 1
    end
    
    local shouldFlushByTime = tick() - lastFlush > FLUSH_INTERVAL
    local shouldFlushByCount = pendingCount >= MAX_PENDING_UPDATES
    
    if (shouldFlushByTime or shouldFlushByCount) and not isFlushingInProgress then
        ContestStoreManager.flushPendingUpdates()
    end
end

function ContestStoreManager.flushPendingUpdates(): ()
    if isFlushingInProgress then
        return -- Already flushing, prevent overlapping flushes
    end
    
    if next(pendingUpdates) == nil then
        return -- Nothing to flush
    end
    
    isFlushingInProgress = true
    
    local contestStoreName = ContestStoreManager.getCurrentMemoryStoreName()
    local currentMemoryStore = MemoryStoreService:GetHashMap(contestStoreName)
    
    -- Create a snapshot of pending updates and clear the original
    local updatesToFlush = {}
    for entryKey, updates in pairs(pendingUpdates) do
        updatesToFlush[entryKey] = {
            votes = updates.votes,
            views = updates.views
        }
    end
    pendingUpdates = {} -- Clear pending updates
    
    print("Flushing pending updates to MemoryStore")
    
    -- Process each update
    for entryKey, updates in pairs(updatesToFlush) do
        if updates.votes ~= 0 or updates.views ~= 0 then
            local success = callWithRetry(function()
                return currentMemoryStore:UpdateAsync(entryKey, function(oldValue)
                    if oldValue then
                        oldValue.votes = (oldValue.votes or 0) + updates.votes
                        oldValue.views = (oldValue.views or 0) + updates.views
                        return oldValue
                    else
                        warn("Entry not found for key during flush:", entryKey)
                        return nil
                    end
                end, 259200)
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

function ContestStoreManager.startPeriodicFlush(): ()
    -- Start a periodic flush every FLUSH_INTERVAL seconds
    task.spawn(function()
        while true do
            task.wait(FLUSH_INTERVAL)
            if not isFlushingInProgress and next(pendingUpdates) then
                ContestStoreManager.flushPendingUpdates()
            end
        end
    end)
    
    -- Start periodic cache updates every CACHE_UPDATE_INTERVAL seconds
    task.spawn(function()
        while true do
            task.wait(CACHE_UPDATE_INTERVAL)
            if not isCacheUpdating then
                ContestStoreManager.updatePublicCache()
            end
        end
    end)
end

-- Update the public cache with all current contest entries
function ContestStoreManager.updatePublicCache(): ()
    if isCacheUpdating then
        return -- Already updating, prevent overlapping updates
    end
    
    isCacheUpdating = true
    print("Updating public cache from MemoryStore...")
    
    local contestStoreName = ContestStoreManager.getCurrentMemoryStoreName()
    local currentMemoryStore = MemoryStoreService:GetHashMap(contestStoreName)
    
    local success, pages = callWithRetry(function()
        return currentMemoryStore:ListItemsAsync(200) 
    end, 3)
    
    if success and pages then
        local newCache = {}
        
        -- Process all pages
        while true do
            local currentPage = pages:GetCurrentPage()
            
            for _, item in ipairs(currentPage) do
                local entryKey = item.key
                local entryData = item.value
                
                -- Merge with any pending updates for this entry
                local pendingVotes = 0
                local pendingViews = 0
                if pendingUpdates[entryKey] then
                    pendingVotes = pendingUpdates[entryKey].votes
                    pendingViews = pendingUpdates[entryKey].views
                end
                
                newCache[entryKey] = {
                    userId = entryData.userId,
                    playerName = entryData.playerName,
                    humanoidDescription = entryData.humanoidDescription,
                    submissionTime = entryData.submissionTime,
                    votes = (entryData.votes or 0) + pendingVotes,
                    views = (entryData.views or 0) + pendingViews
                }
            end
            
            if pages.IsFinished then
                break
            else
                local pageSuccess = pcall(function()
                    pages:AdvanceToNextPageAsync()
                end)
                if not pageSuccess then
                    warn("Failed to advance to next page during cache update")
                    break
                end
            end
        end
        
        -- Update the public cache
        publicCache = newCache
        lastCacheUpdate = tick()
        
        local entryCount = 0
        for _ in pairs(publicCache) do
            entryCount += 1
        end
        print("Public cache updated with", entryCount, "entries")
    else
        warn("Failed to update public cache")
    end
    
    isCacheUpdating = false
end

-- Get the public cache (all contest entries with current vote/view counts)
function ContestStoreManager.getPublicCache(): {}
    return publicCache
end

-- Get a specific entry from the public cache (with pending updates included)
function ContestStoreManager.getCachedEntry(entryKey: string): {}?
    local cachedEntry = publicCache[entryKey]
    if not cachedEntry then
        return nil
    end
    
    -- Create a copy and add any pending updates
    local entry = {
        userId = cachedEntry.userId,
        playerName = cachedEntry.playerName,
        humanoidDescription = cachedEntry.humanoidDescription,
        submissionTime = cachedEntry.submissionTime,
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

-- Force update the public cache (useful for debugging)
function ContestStoreManager.forceUpdateCache(): ()
    ContestStoreManager.updatePublicCache()
end

-- Force flush all pending updates (useful for shutdown/cleanup)
function ContestStoreManager.forceFlush(): ()
    ContestStoreManager.flushPendingUpdates()
end

-- Get current pending updates for debugging
function ContestStoreManager.getPendingUpdates(): {}
    return pendingUpdates
end

-- Get cache statistics for debugging
function ContestStoreManager.getCacheStats(): {}
    local entryCount = 0
    for _ in pairs(publicCache) do
        entryCount += 1
    end
    
    local pendingCount = 0
    for _ in pairs(pendingUpdates) do
        pendingCount += 1
    end
    
    return {
        cacheEntries = entryCount,
        pendingUpdates = pendingCount,
        lastCacheUpdate = lastCacheUpdate,
        timeSinceLastCacheUpdate = tick() - lastCacheUpdate,
        isCacheUpdating = isCacheUpdating,
        isFlushingInProgress = isFlushingInProgress
    }
end

return ContestStoreManager