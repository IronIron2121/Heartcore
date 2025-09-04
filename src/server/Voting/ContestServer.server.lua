--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Voting = ServerScriptService:WaitForChild("Voting")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes / Bindables
local GetContestSubmissionsCache = Remotes:WaitForChild("GetContestSubmissionsCache")
local GetBalancedOutfit = Remotes:WaitForChild("GetBalancedOutfit")
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")


-- Modules 
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))

local function initialise()
    -- check if there is a contest
    -- if there isn't, then initialise one
end

local function onPhaseChanged()
    ContestStoreManager.initialiseNewContest()
end
 
local function getContestSubmissionsCache()
    return ContestStoreManager.getPublicCache()
end

local function getBalancedOutfit()
    return ContestStoreManager.getBalancedOutfit()
end

initialise()

GetContestSubmissionsCache.OnServerInvoke = getContestSubmissionsCache
PhaseChanged.Event:Connect(onPhaseChanged)
GetBalancedOutfit.OnServerInvoke = getBalancedOutfit