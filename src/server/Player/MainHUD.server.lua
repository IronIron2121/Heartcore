--!strict

--[[
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Trackers 	= ReplicatedStorage:WaitForChild("Trackers")
local Remotes 	= ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local PlayerTracker = require(Trackers:WaitForChild("PlayerTracker"))

-- Remotes / Bindables
local CloseShopButtonClickedAsync = Remotes:WaitForChild("CloseShopButtonClicked")

local function playerClickedCloseShopButton(player : Player)
	local playerDetails = PlayerTracker.getPlayerDetails(player)
	if playerDetails then
		playerDetails:unclaimShop()
	end
end

CloseShopButtonClickedAsync.OnServerEvent:Connect(playerClickedCloseShopButton)
]]