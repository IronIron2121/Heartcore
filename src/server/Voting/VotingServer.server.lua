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
local VotingStoreManager = require(Voting:WaitForChild("VotingStoreManager"))
local DataManager = require(Data:WaitForChild("DataManager"))

local function onPhaseChanged()
    -- Handle phase transition - voting manager will update theme and point to yesterday
    VotingStoreManager.onPhaseTransition()
end
 
local function getContestSubmissionsCache()
    return VotingStoreManager.getPublicCache()
end

local function getBalancedOutfit(player: Player)
    local balancedOutfit = VotingStoreManager.getBalancedOutfit(player)
    return balancedOutfit
end

-- Register votes and views for a given player's vote
-- Each vote: player chooses one outfit to vote on out of three options (all three get a view)
local function submitVote(player: Player, voteId: string, viewIds: {string})    
    VotingStoreManager.addVotes(tostring(voteId), 1)

    for _, id in ipairs(viewIds) do
        VotingStoreManager.addViews(tostring(id), 1)
    end

    DataManager.AddExp(player, 1)
end

GetContestSubmissionsCache.OnServerInvoke = getContestSubmissionsCache
PhaseChanged.Event:Connect(onPhaseChanged)
GetBalancedOutfit.OnServerInvoke = getBalancedOutfit
PlayerSubmittedVote.OnServerEvent:Connect(submitVote)