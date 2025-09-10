--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Voting = ServerScriptService:WaitForChild("Voting")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Data = ServerScriptService:WaitForChild("Data")

-- Remotes / Bindables
local GetContestSubmissionsCache = Remotes:WaitForChild("GetContestSubmissionsCache")
local GetBalancedOutfit = Remotes:WaitForChild("GetBalancedOutfit")
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")
local PlayerSubmittedVote = Remotes:WaitForChild("PlayerSubmittedVote")

-- Modules 
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))
local DataManager = require(Data:WaitForChild("DataManager"))

local function onPhaseChanged()
    ContestStoreManager.initialiseNewContest()
end
 
local function getContestSubmissionsCache()
    return ContestStoreManager.getPublicCache()
end

local function getBalancedOutfit()
    local BalancedOutfit = ContestStoreManager.getBalancedOutfit()

    print("Now returning", BalancedOutfit)
    return BalancedOutfit
end

-- register votes and views for a given player's vote (for each vote, a player chooses one outfit to vote on out of three options, which all recieve a view)
local function submitVote(player: Player, voteId: string, viewIds: {string})    
    ContestStoreManager.addVotes(tostring(voteId), 1)

    for _, id in ipairs(viewIds) do
        ContestStoreManager.addViews(tostring(id), 1)
    end


    DataManager.AddExp(player, 1)
    --print("Just added votes and views to ", voteId, viewIds)
    --print(ContestStoreManager.getPublicCache())
end

GetContestSubmissionsCache.OnServerInvoke = getContestSubmissionsCache
PhaseChanged.Event:Connect(onPhaseChanged)
GetBalancedOutfit.OnServerInvoke = getBalancedOutfit
PlayerSubmittedVote.OnServerEvent:Connect(submitVote)