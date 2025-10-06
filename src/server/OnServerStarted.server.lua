--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))


local function initialiseVoting()
    GameTimer.initialiseTimer()
    SubmissionStoreManager.initialise()
    ContestStoreManager.initialise()

end

initialiseVoting()  