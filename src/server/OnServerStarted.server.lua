--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))


local function initialiseVoting()
    GameTimer.initialiseTimer()
    ContestStoreManager.initialise()
end

initialiseVoting()  