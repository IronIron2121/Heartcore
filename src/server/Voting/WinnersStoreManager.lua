--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local dailyWinners = workspace:WaitForChild("dailyWinners")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))
local ThemeManager = require(Voting:WaitForChild("ThemeManager"))

-- Instances
local leaderboard = dailyWinners:WaitForChild("leaderboard")
local leaderboardScreen = leaderboard:WaitForChild("leaderboardScreen")
--local WinnersThemeHolder = leaderboardScreen:WaitForChild("WinnersThemeHolder")


-- GUI Instances
local leaderboardGui = leaderboardScreen:WaitForChild("LeaderboardGui")
local leaderboardFrame = leaderboardGui:WaitForChild("LeaderboardFrame")

local WinnersThemeGui = leaderboardScreen:WaitForChild("WinnersThemeGui")
local WinnersThemeFrame = WinnersThemeGui:WaitForChild("WinnersThemeFrame")
local ThemeLabel = WinnersThemeFrame:WaitForChild("ThemeLabel")

-- Types
type RigModel = Model & {
    Humanoid : Humanoid
}

local podiumRigs = {
    [1] = dailyWinners:WaitForChild("FirstPlace") :: RigModel,
    [2] = dailyWinners:WaitForChild("SecondPlace") :: RigModel,
    [3] = dailyWinners:WaitForChild("ThirdPlace") :: RigModel
}

local WinnersStoreManager = {}

function WinnersStoreManager.getCurrentMemoryStoreName(): string
    return tostring(GameTimer.getCurrentPhasePrefix()) .. Constants.WINNERS_MEMORYSTORE_NAME
end

function WinnersStoreManager.getCurrentMemoryStore(): MemoryStoreHashMap?
    local winnerStoreName = WinnersStoreManager.getCurrentMemoryStoreName()
    local success, memoryStore = callWithRetry(
        function()
            return MemoryStoreService:GetHashMap(winnerStoreName)
        end,
        3
    )

    if success then
        return memoryStore
    else
        warn("Failed to get winners memory store")
        return nil
    end
end

function WinnersStoreManager.getCurrentWinners(): {}?
    local currentWinnerStore = WinnersStoreManager.getCurrentMemoryStore()
    if not currentWinnerStore then
        return nil
    end

    local success, winners = callWithRetry(
        function()
            return currentWinnerStore:GetAsync(Constants.CURRENT_WINNERS_KEY)
        end,
        5
    )

    if success then 
        return winners
    else
        warn("Failed to get current winners")
        return nil
    end
end

function WinnersStoreManager.getCurrentTopTwenty(): {}?
    local currentWinnerStore = WinnersStoreManager.getCurrentMemoryStore()
    if not currentWinnerStore then
        return nil
    end

    local success, topTwenty = callWithRetry(
        function()
            return currentWinnerStore:GetAsync(Constants.CURRENT_TOP_TWENTY_KEY)
        end,
        5
    )

    if success then 
        return topTwenty
    else
        warn("Failed to get current top twenty")
        return nil
    end
end

function WinnersStoreManager.updateWinnersThemeDisplay()
    warn("UPDATING WINNERS THEME DISPLAY")
    local erePreviousTheme = ThemeManager.getErePreviousThemeName()
    ThemeLabel.Text = erePreviousTheme
end

function WinnersStoreManager.updateTopTwentyLeaderboard()
    local topTwenty = WinnersStoreManager.getCurrentTopTwenty()
    if not topTwenty then return end
    local lengthOfList = #topTwenty

    -- Clear existing labels
    for _, child in ipairs(leaderboardFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    -- Create new labels for top twenty
    for i = 1, lengthOfList do
        local currentEntry = topTwenty[i]
        local currentEntryId = currentEntry.userId

        local success, playerName = pcall(function()
            return Players:GetNameFromUserIdAsync(currentEntryId)
        end)

        if not success then
            warn("Failed to get username for userId:", currentEntryId)
            continue
        end

        local newLabel = Instance.new("TextLabel")
        newLabel.Parent = leaderboardFrame
        newLabel.LayoutOrder = i
        newLabel.Text = i .. ". " .. playerName .. " - " .. currentEntry.votes .. " votes"
        newLabel.Size = UDim2.new(1, 0, 0, 30)
        newLabel.BackgroundTransparency = 1
        newLabel.TextColor3 = Color3.fromRGB(92, 96, 214)
        newLabel.TextSize = 75
        newLabel.Font = Enum.Font.GothamBold
    end
end

function WinnersStoreManager.updateWinnersPodiums()
    local currentWinners = WinnersStoreManager.getCurrentWinners()
    if not currentWinners then 
        warn("Error when loading current winners!")
        return
    end

    for index, entry in ipairs(currentWinners) do
        local description = entry.humanoidDescription
        
        if not description then 
            warn("No humanoid description for winner at index:", index)
            description = Instance.new("HumanoidDescription")
        else
            description = SerialisationService.UnserialiseHumanoidDescription(description)
        end

        local rig = podiumRigs[index]

        if not rig then
            warn("No rig at index:", index)
            continue
        end

        local success = pcall(function()
            podiumRigs[index].Humanoid:ApplyDescription(description)
        end)
        
        if not success then
            warn("Failed to apply description to rig at index:", index)
        end
    end

    
end

-- Get all submission store names for a given phase
local function getSubmissionStoreNames(phasePrefix: string): {string}
    local storeNames = {}
    
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
    
    local maxStoreNumber = info.currentStoreNumber or 1
    for i = 1, maxStoreNumber do
        local storeName = phasePrefix .. Constants.SUBMISSION_MEMORYSTORE_NAME .. i
        table.insert(storeNames, storeName)
    end
    
    print("Found", #storeNames, "submission stores for phase:", phasePrefix)
    return storeNames
end

-- Get top N entries from a single submission store (sorted by votes)
local function getTopEntriesFromStore(storeName: string, topN: number): {{}}
    local topEntries = {}
    
    local success, store = callWithRetry(function()
        return MemoryStoreService:GetSortedMap(storeName)
    end, 3)
    
    if not success or not store then
        warn("Failed to get submission store:", storeName)
        return topEntries
    end
    
    -- GetRangeAsync doesn't sort by votes, so we need to get all and sort manually
    local rangeSuccess, items = callWithRetry(function()
        return store:GetRangeAsync(Enum.SortDirection.Ascending, 200)
    end, 3)
    
    if not rangeSuccess or not items then
        warn("Failed to get range from store:", storeName)
        return topEntries
    end
    
    -- Convert to array and sort by votes
    local allEntries = {}
    for _, item in ipairs(items) do
        table.insert(allEntries, {
            key = item.key,
            userId = item.value.userId,
            humanoidDescription = item.value.humanoidDescription,
            votes = item.value.votes or 0,
            views = item.value.views or 0
        })
    end
    
    -- Sort by votes descending
    table.sort(allEntries, function(a, b)
        return a.votes > b.votes
    end)
    
    -- Take top N
    for i = 1, math.min(topN, #allEntries) do
        table.insert(topEntries, allEntries[i])
    end
    
    return topEntries
end

function WinnersStoreManager.initialise()
    print("Initializing WinnersStoreManager...")
    
    -- Update podiums and leaderboard with current winners on server start
    WinnersStoreManager.updateWinnersPodiums()
    WinnersStoreManager.updateTopTwentyLeaderboard()
    WinnersStoreManager.updateWinnersThemeDisplay()
    
    print("WinnersStoreManager initialized successfully")
end

function WinnersStoreManager.setNewWinners()
    -- Get ereyesterday's phase prefix (day before yesterday)
    local erePreviousPrefix = GameTimer.getErePreviousPhasePrefix()
    
    if not erePreviousPrefix then
        warn("No ereyesterday phase available yet - cannot determine winners")
        return false
    end
    
    print("Determining winners from phase:", erePreviousPrefix)
    
    -- Get all submission stores for that phase
    local storeNames = getSubmissionStoreNames(erePreviousPrefix)
    
    if #storeNames == 0 then
        warn("No submission stores found for phase:", erePreviousPrefix)
        return false
    end
    
    -- Collect top 5 from each store
    local topCandidates = {}
    for _, storeName in ipairs(storeNames) do
        local topFromStore = getTopEntriesFromStore(storeName, 5)
        for _, entry in ipairs(topFromStore) do
            table.insert(topCandidates, entry)
        end
    end
    
    if #topCandidates == 0 then
        warn("No entries found across all stores for phase:", erePreviousPrefix)
        return false
    end
    
    print("Collected", #topCandidates, "top candidates from", #storeNames, "stores")
    
    -- Sort all candidates by votes
    table.sort(topCandidates, function(a, b)
        return a.votes > b.votes
    end)
    
    -- Get top 3
    local first_place = topCandidates[1] or {userId = 0, votes = -1, humanoidDescription = nil}
    local second_place = topCandidates[2] or {userId = 0, votes = -1, humanoidDescription = nil}
    local third_place = topCandidates[3] or {userId = 0, votes = -1, humanoidDescription = nil}

    -- Get top 20
    local topTwenty = {}
    for i = 1, 20 do
        if not topCandidates[i] then
            break
        end
        table.insert(topTwenty, topCandidates[i])
    end
    
    -- Save winners to current phase's winner store
    local winnersStore = WinnersStoreManager.getCurrentMemoryStore()
    if not winnersStore then
        warn("Failed to get winner store!")
        return false
    end

    local success = callWithRetry(
        function()
            return winnersStore:SetAsync(Constants.CURRENT_WINNERS_KEY, {
                first_place, 
                second_place, 
                third_place
            }, Constants.MEMORYSTORE_STORE_DURATION)
        end,
        10
    )

    -- Save top twenty to current phase's winner store
    local twentySuccess = callWithRetry(
        function()
            return winnersStore:SetAsync(Constants.CURRENT_TOP_TWENTY_KEY, topTwenty, Constants.MEMORYSTORE_STORE_DURATION)
        end,
        3
    )

    
    if success and twentySuccess then
        print("Winners updated successfully for phase:", GameTimer.getCurrentPhasePrefix())
        print("Winners from phase:", erePreviousPrefix)
        print("1st Place:", first_place.userId, "with", first_place.votes, "votes")
        print("2nd Place:", second_place.userId, "with", second_place.votes, "votes") 
        print("3rd Place:", third_place.userId, "with", third_place.votes, "votes")
        print("Top 20 saved successfully")
        WinnersStoreManager.updateWinnersPodiums()
        WinnersStoreManager.updateTopTwentyLeaderboard()
        WinnersStoreManager.updateWinnersThemeDisplay()
        return true
    else
        warn("Failed to set new winners or top twenty")
        return false
    end
end

return WinnersStoreManager