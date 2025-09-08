--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))

local function initialiseVoting()
    --ContestStoreManager.updatePublicCache()
end

initialiseVoting()