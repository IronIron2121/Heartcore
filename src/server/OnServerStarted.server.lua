--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local VotingStoreManager = require(Voting:WaitForChild("VotingStoreManager"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))


local function initialiseVoting()
    GameTimer.initialiseTimer()
    VotingStoreManager.initialise()
end

initialiseVoting()  