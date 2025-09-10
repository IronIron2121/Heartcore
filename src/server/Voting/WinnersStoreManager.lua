--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local MemoryStoreService = game:GetService("MemoryStoreService") -- We'll start by using memory stores and change over to datastores if the needs arises
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local dailyWinners = workspace:WaitForChild("dailyWinners")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Instances
local podiumRigs = {
    [1] = dailyWinners:WaitForChild("FirstPlace") :: Model & {Humanoid},
    [2] = dailyWinners:WaitForChild("SecondPlace") :: Model & {Humanoid},
    [3] = dailyWinners:WaitForChild("ThirdPlace") :: Model & {Humanoid}
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
        end

        description = SerialisationService.UnserialiseHumanoidDescription(description)

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

function WinnersStoreManager.setNewWinners()
    local publicCache = ContestStoreManager.getPublicCache()

    if not publicCache then 
        warn("No public cache; can't get it!") 
        return false
    end

    local first_place = {
        userId = 0,
        votes = -1
    }  
    local second_place = {
        userId = 0,
        votes = -1
    }
    local third_place = {
        userId = 0,
        votes = -1
    }
    
    for playerId, entry in pairs(publicCache) do
        if entry.votes > first_place.votes then
            -- New first place: cascade the others down
            third_place = second_place
            second_place = first_place
            first_place = entry
        elseif entry.votes > second_place.votes then
            -- New second place: third place gets old second
            third_place = second_place
            second_place = entry
        elseif entry.votes > third_place.votes then
            -- New third place
            third_place = entry
        end
    end

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
            }, 172800)
        end,
        10
    )
    
    if success then
        print("Winners updated successfully")
        print("1st Place:", first_place.userId, "with", first_place.votes, "votes")
        print("2nd Place:", second_place.userId, "with", second_place.votes, "votes") 
        print("3rd Place:", third_place.userId, "with", third_place.votes, "votes")
        WinnersStoreManager.updateWinnersPodiums() -- Update podiums immediately
        return true
    else
        warn("Failed to set new winners")
        return false
    end
end

return WinnersStoreManager