--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local VotingStoreManager = require(Voting:WaitForChild("VotingStoreManager"))
local ThemeManager = require(Voting:WaitForChild("ThemeManager"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))



local function initialiseVoting()
    GameTimer.initialiseTimer()
    VotingStoreManager.initialise()
    SubmissionStoreManager.initialise()
    ThemeManager.initialise()
end

initialiseVoting()  