--!strict

-- Services
local ServerScriptService 		= game:GetService("ServerScriptService")
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")
local Players 					= game:GetService("Players")

-- Folders
local Trackers 					= ReplicatedStorage:WaitForChild("Trackers")
local Voting 					= ServerScriptService:WaitForChild("Voting")

-- Module Scripts
local PlayerVotedOutfitsTracker = require(Voting:WaitForChild("PlayerVotedOutfitsTracker"))
local PlayerTracker 			= require(Trackers:WaitForChild("PlayerTracker"))

-- Modules


local function onPlayerRemoved(player: Player)
	local playerDetails = PlayerTracker.getPlayerDetails(player)
	if playerDetails then
		playerDetails:unclaimShop()
	else
		warn("No player details!", playerDetails)
		--assert(playerDetails, "player has no details")
	end

	PlayerVotedOutfitsTracker.OnPlayerRemoved(player)
end

Players.PlayerRemoving:Connect(onPlayerRemoved)