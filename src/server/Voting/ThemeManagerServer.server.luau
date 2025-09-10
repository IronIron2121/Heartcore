--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local CacheBasedBalancedSelector = require(Voting:WaitForChild("CacheBasedBalancedSelector"))
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Remotes / Bindables
local SetNewWinnersBindable = Bindables:WaitForChild("SetNewWinners")
local ThemeChangedRemote = RemotesFolder:WaitForChild("ThemeChanged")

local ContestStoreManager = {}

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

-- Current theme data
local currentTheme = nil

-- Caching variables
local pendingUpdates = {} -- {entryKey = {votes = 0, views = 0}}
local lastFlush = tick()
local FLUSH_INTERVAL = 30 -- seconds
local MAX_PENDING_UPDATES = 50 -- flush if we hit this many pending updates
local isFlushingInProgress = false

-- Public cache for current contest entries
local publicCache = {} -- {entryKey = {id, description, votes, views}}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 120 
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

function ContestStoreManager.getCurrentTheme(): {}?
    return currentTheme
end

function ContestStoreManager.getThemeName(): string
    return currentTheme and currentTheme.Theme or "Loading..."
end

function ContestStoreManager.getThemeTimeChanged(): number?
    return currentTheme and currentTheme.TimeChanged or nil
end

function ContestStoreManager.getAvailableThemes(): {string}
    return AVAILABLE_THEMES
end

local function getThemeMemoryStore()
    local success, memoryStore = callWithRetry(
        function()
            return MemoryStoreService:GetSortedMap(Constants.CONTEST_MEMORYSTORE_NAME)
        end,
        3
    )
    return success and memoryStore or nil
end

local function initializeTheme(): boolean
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
        local newTheme = createNewTheme()
        
        local setSuccess, result = callWithRetry(
            function()
                return themeMemoryStore:SetAsync(
                    Constants.CURRENT_THEME_KEY,
                    newTheme,
                    Constants.MEMORYSTORE_STORE_DURATION
                )
            end,
            5
        )
        
        if setSuccess then
            currentTheme = newTheme
            ThemeChangedRemote:FireAllClients(newTheme)
            print("Initialized new theme:", newTheme.Theme)
            return true
        else
            warn("Failed to set new theme:", result)
            return false
        end
    else
        currentTheme = currentThemeData
        ThemeChangedRemote:FireAllClients(currentThemeData)
        print("Loaded existing theme:", currentThemeData.Theme)
        return true
    end
end

local function updateTheme(): boolean
    print("Updating to new theme...")
    local newTheme = createNewTheme()
    
    local themeMemoryStore = getThemeMemoryStore()
    if not themeMemoryStore then
        warn("Failed to get theme memory store for update")
        return false
    end
    
    local success, result = callWithRetry(
        function()
            return themeMemoryStore:SetAsync(
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
        print("Updated to new theme:", newTheme.Theme)
        return true
    else
        warn("Failed to update theme:", result)
        return false
    end
end

-- Original ContestStoreManager functions (modified to include theme)
function ContestStoreManager.initialise(): ()
    -- Initialize theme first
    local themeSuccess = initializeTheme()
    if not themeSuccess then
        error("Failed to initialize theme system")
    end
    
    ContestStoreManager.updatePublicCache()
end

function ContestStoreManager.getCurrentMemoryStoreName(): string
    return tostring(GameTimer.getCurrentPhasePrefix()) .. Constants.CONTEST_MEMORYSTORE_NAME
end

function ContestStoreManager.getCurrentMemoryStore()
    local contestStoreName = ContestStoreManager.getCurrentMemoryStoreName()
    local success, memoryStore = callWithRetry(
        function()
            return MemoryStoreService:GetHashMap(contestStoreName)
        end,
        3
    )

    return memoryStore or success 
end

function ContestStoreManager.initialiseNewContest(): boolean
    -- Update theme for new contest
    local themeUpdateSuccess = updateTheme()
    if not themeUpdateSuccess then
        warn("Failed to update theme for new contest")
        -- Continue anyway, as contest can function without theme
    end

    -- Set new winners before changing over...
    local complete = SetNewWinnersBindable:Invoke()

    if not complete then
        warn("Could not set new winners...")
    end

    local currentMemoryStore = ContestStoreManager.getCurrentMemoryStore()
    if not currentMemoryStore then
        warn("No current memorystore!")
        return false
    end

    local allSubmissions = SubmissionStoreManager:GetPreviousPhaseEntries()

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
            humanoidDescription = entry.humanoidDescription,
            votes = 0,
            views = 0,
            theme = currentTheme and currentTheme.Theme or "Unknown" -- Add theme to submission
        }
         
        -- Add the contest submission at the key of the corresponding submission
        local success = callWithRetry(function()
            return currentMemoryStore:SetAsync(key, contestSubmission, Constants.MEMORYSTORE_STORE_DURATION)
        end, 3)
        
        if success then
            successCount = successCount + 1
            print("Added contest entry for:", key, "with theme:", contestSubmission.theme)
        else
            warn("Failed to add contest entry for:", key)
        end
    end
    
    print(string.format("Contest initialization complete: %d/%d entries added successfully with theme: %s", 
        successCount, totalCount, currentTheme and currentTheme.Theme or "Unknown"))
    
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
    warn("Adding views to ", entryKey, "with type,", typeof(entryKey))
    -- Initialize entry in pending updates if it doesn't exist
    if not pendingUpdates[entryKey] then
        warn("No pre-existing entry for this key!")
        pendingUpdates[entryKey] = {votes = 0, views = 0}
    end
    
    -- Add to pending updates
    pendingUpdates[entryKey].views += viewAmount
    
    -- Also update the public cache immediately for real-time UI updates
    if publicCache[entryKey] then 
        publicCache[entryKey].views += viewAmount
    else
        warn("No public cache entry for this outfit!")
    end
    
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
    
    -- Also update the public cache immediately for real-time UI updates
    if publicCache[entryKey] then
        publicCache[entryKey].votes += voteAmount
    end
    
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
        return 
    end
    
    if next(pendingUpdates) == nil then
        return 
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
        return currentMemoryStore:ListItemsAsync(10) 
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
                    theme = entryData.theme or (currentTheme and currentTheme.Theme) or "Unknown", -- Include theme
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
        print("Public cache updated with", entryCount, "entries for theme:", 
            currentTheme and currentTheme.Theme or "Unknown")

        -- Rebuild selection buckets from the fresh cache
        local rebuildSuccess = balancedSelector:onCacheUpdated(publicCache)
        if rebuildSuccess then
            print("Selection buckets rebuilt successfully")
        else
            warn("Failed to rebuild selection buckets")
        end
        
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

-- Get a balanced outfit selection (main method for voting UI)
function ContestStoreManager.getBalancedOutfit(): string?
    return balancedSelector:selectOutfit()
end

-- Get selection system statistics for monitoring
function ContestStoreManager.getSelectionStats(): {}
    return balancedSelector:getStats()
end

-- Get detailed selection statistics for debugging
function ContestStoreManager.getDetailedSelectionStats(): {}
    return balancedSelector:getDetailedStats()
end

-- Force rebuild selection buckets (for debugging)
function ContestStoreManager.rebuildSelectionBuckets(): boolean
    return balancedSelector:onCacheUpdated(publicCache)
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
        isFlushingInProgress = isFlushingInProgress,
        currentTheme = currentTheme and currentTheme.Theme or "None",
        themeTimeChanged = currentTheme and currentTheme.TimeChanged or nil
    }
end

-- Force update theme (useful for admin controls)
function ContestStoreManager.forceUpdateTheme(): boolean
    return updateTheme()
end

return ContestStoreManager