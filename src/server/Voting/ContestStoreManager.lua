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
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Remotes / Bindables
local SetNewWinnersBindable = Bindables:WaitForChild("SetNewWinners")
local ThemeChangedRemote = RemotesFolder:WaitForChild("ThemeChanged")

-- Instances
local BillboardHolder = votingZone:WaitForChild("BillboardHolder")
local ThemeNameBillboard = BillboardHolder:WaitForChild("ThemeNameBillboard")
local ThemeNameTextLabel = ThemeNameBillboard:WaitForChild("TextLabel")

-- Memory Stores
local CacheLockStore = MemoryStoreService:GetHashMap("CacheRefreshLocks")

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
local pendingUpdates = {}
local lastFlush = tick()
local FLUSH_INTERVAL = 60 
local MAX_PENDING_UPDATES = 50
local isFlushingInProgress = false

-- Public cache for current contest entries
local publicCache = {}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 500 
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

local function updateThemeBillboardText()
    ThemeNameTextLabel.Text = ContestStoreManager.getThemeName()
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

local function initializeTheme(): boolean
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
        return updateTheme(themeMemoryStore)
    else
        currentTheme = currentThemeData
        ThemeChangedRemote:FireAllClients(currentThemeData)
        updateThemeBillboardText()
        print("Loaded existing theme:", currentThemeData.Theme)
        return true
    end
end

local function attemptCacheRefresh(): boolean
    local lockKey = "contest_cache_refresh"
    
    local success, result = callWithRetry(function()
        return CacheLockStore:UpdateAsync(lockKey, function(currentLock)
            local now = DateTime.now().UnixTimestamp
            
            -- Lock is free or stale (timeout after 2 minutes in case server crashes mid-refresh)
            if currentLock == nil or (now - currentLock.startTime) > 60 then
                return {
                    serverId = game.JobId,
                    startTime = now
                }
            else
                return nil
            end
        end, 300)
    end, 3)
    
    return success and result and result.serverId == game.JobId
end

function ContestStoreManager.initialise(): ()
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

    if success then
        return memoryStore
    else
        warn("Failed to get contest memory store")
        return nil
    end
end

function ContestStoreManager.initialiseNewContest(): boolean
    local complete = SetNewWinnersBindable:Invoke()

    if not complete then
        warn("Could not set new winners...")
    end
    
    local themeUpdateSuccess = updateTheme()
    if not themeUpdateSuccess then
        warn("Failed to update theme for new contest")
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
        
        local contestSubmission = {
            userId = entry.userId,
            humanoidDescription = entry.humanoidDescription,
            votes = 0,
            views = 0,
        }
         
        local success = callWithRetry(function()
            return currentMemoryStore:SetAsync(key, contestSubmission, Constants.MEMORYSTORE_STORE_DURATION)
        end, 3)
        
        if success then
            successCount = successCount + 1
        else
            warn("Failed to add contest entry for:", key)
        end
    end
    
    print(string.format("Contest initialization complete: %d/%d entries added successfully with theme: %s", 
        successCount, totalCount, currentTheme and currentTheme.Theme or "Unknown")
    )
    
    if successCount > 0 then
        ContestStoreManager.startPeriodicFlush()
        ContestStoreManager.updatePublicCache()
        return true
    else
        return false
    end
end

function ContestStoreManager.addViews(entryKey: string, viewAmount: number): ()
    if not pendingUpdates[entryKey] then
        pendingUpdates[entryKey] = {votes = 0, views = 0}
    end
    
    pendingUpdates[entryKey].views += viewAmount
    
    if publicCache[entryKey] then 
        publicCache[entryKey].views += viewAmount
    end
    
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
    if not pendingUpdates[entryKey] then
        pendingUpdates[entryKey] = {votes = 0, views = 0}
    end
    
    pendingUpdates[entryKey].votes += voteAmount
    
    if publicCache[entryKey] then
        publicCache[entryKey].votes += voteAmount
    end
    
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
    
    local updatesToFlush = {}
    for entryKey, updates in pairs(pendingUpdates) do
        updatesToFlush[entryKey] = {
            votes = updates.votes,
            views = updates.views
        }
    end
    pendingUpdates = {}
    
    print("Flushing pending updates to MemoryStore")
    
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
    task.spawn(function()
        while true do
            task.wait(FLUSH_INTERVAL)
            if not isFlushingInProgress and next(pendingUpdates) then
                ContestStoreManager.flushPendingUpdates()
            end
        end
    end)
    
    task.spawn(function()
        while true do
            task.wait(CACHE_UPDATE_INTERVAL)
            if not isCacheUpdating and attemptCacheRefresh() then
                ContestStoreManager.updatePublicCache()
            else
                print("Skipping cache refresh - another server is handling it")
            end
        end
    end)
end

function ContestStoreManager.updatePublicCache(): ()
    if isCacheUpdating then
        return 
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
        
        while true do
            local currentPage = pages:GetCurrentPage()
            
            for _, item in ipairs(currentPage) do
                local entryKey = item.key
                local entryData = item.value
                
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
                    theme = entryData.theme or (currentTheme and currentTheme.Theme) or "Unknown",
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
        
        publicCache = newCache
        lastCacheUpdate = tick()
        
        local entryCount = 0
        for _ in pairs(publicCache) do
            entryCount += 1
        end
        print("Public cache updated with", entryCount, "entries for theme:", 
            currentTheme and currentTheme.Theme or "Unknown")

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

function ContestStoreManager.getPublicCache(): {}
    return publicCache
end

function ContestStoreManager.getCachedEntry(entryKey: string): {}?
    local cachedEntry = publicCache[entryKey]
    if not cachedEntry then
        return nil
    end
    
    local entry = {
        userId = cachedEntry.userId,
        playerName = cachedEntry.playerName,
        humanoidDescription = cachedEntry.humanoidDescription,
        submissionTime = cachedEntry.submissionTime,
        theme = cachedEntry.theme,
        votes = cachedEntry.votes,
        views = cachedEntry.views
    }
    
    if pendingUpdates[entryKey] then
        entry.votes += pendingUpdates[entryKey].votes
        entry.views += pendingUpdates[entryKey].views
    end
    
    return entry
end

function ContestStoreManager.getBalancedOutfit(): string?
    return balancedSelector:selectOutfit()
end

function ContestStoreManager.forceUpdateCache(): ()
    ContestStoreManager.updatePublicCache()
end

function ContestStoreManager.forceFlush(): ()
    ContestStoreManager.flushPendingUpdates()
end

function ContestStoreManager.getPendingUpdates(): {}
    return pendingUpdates
end

return ContestStoreManager