--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))

local function onServerClose()
    warn("Server Closing")
    --ContestStoreManager.forceFlush()
    warn("Server Closed...")
end

game:BindToClose(onServerClose) 