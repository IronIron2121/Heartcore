--!strict

-- Services
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")
local Players 					= game:GetService("Players")

-- Folders
local Trackers 					= ReplicatedStorage:WaitForChild("Trackers")

-- Module Scripts
local PlayerTracker 			= require(Trackers:WaitForChild("PlayerTracker"))

local function onPlayerRemoved(player: Player)
	local playerDetails = PlayerTracker.getPlayerDetails(player)
	if playerDetails then
		playerDetails:unclaimShop()
	else
		warn("No player details!", playerDetails)
		--assert(playerDetails, "player has no details")
	end
end

Players.PlayerRemoving:Connect(onPlayerRemoved)