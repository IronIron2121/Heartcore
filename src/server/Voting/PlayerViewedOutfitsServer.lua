--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")

-- Modules
local PlayerViewedOutfitsTracker = require(Voting:WaitForChild("PlayerViewedOutfitsTracker"))
