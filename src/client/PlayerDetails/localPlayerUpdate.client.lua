--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Trackers = ReplicatedStorage:WaitForChild("Trackers")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Instances
local localPlayer = Players.LocalPlayer

-- Modules
local Types = require(Utility:WaitForChild("Types"))
local localPlayerDetails = require(Trackers:WaitForChild("localPlayerDetails")) 

-- Remotes
local PlayerUnclaimedShopAsync = Remotes:WaitForChild("PlayerUnclaimedShop")
local PlayerClaimedShopAsync = Remotes:WaitForChild("PlayerClaimedShop")
local UpdateLocalPlayerDetailsAsync = Remotes:WaitForChild("UpdateLocalPlayerDetails")

local function onShopUpdated(playerDetails : Types.PlayerDetails)
	print("Updating player details")
	localPlayerDetails.update(playerDetails)
end

PlayerClaimedShopAsync.OnClientEvent:Connect(onShopUpdated)
PlayerUnclaimedShopAsync.OnClientEvent:Connect(onShopUpdated)
UpdateLocalPlayerDetailsAsync.OnClientEvent:Connect(onShopUpdated)