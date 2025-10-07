--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local VotingStoreManager = require(Voting:WaitForChild("VotingStoreManager"))

local function onServerClose()
    warn("Server Closing")
    --VotingStoreManager.forceFlush()
    warn("Server Closed...")
end

game:BindToClose(onServerClose) 