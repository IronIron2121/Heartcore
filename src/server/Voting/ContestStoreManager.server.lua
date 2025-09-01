--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local ContestStoreManager = require(Voting:WaitForChild("ContestStoreManager"))

local function initialise()
    -- check if there is a contest
    -- if there isn't, then initialise one
end

initialise()