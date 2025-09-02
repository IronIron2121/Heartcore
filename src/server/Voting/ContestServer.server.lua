--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Voting = ServerScriptService:WaitForChild("Voting")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes / Bindables
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")
local GetContestSubmissionsCache = Remotes:WaitForChild("GetContestSubmissionsCache")

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
    print("Public cache")
    return ContestStoreManager.getPublicCache()
end

initialise()

GetContestSubmissionsCache.OnServerInvoke = getContestSubmissionsCache
PhaseChanged.Event:Connect(onPhaseChanged)