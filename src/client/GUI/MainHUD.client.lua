--[[
	Contains functionality for player HUD gui
]]

print("Initialising shop buttons etc etc")

-- Services
local Players 			= game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Bindables		= ReplicatedStorage:WaitForChild("Bindables")
local Getters 		= ReplicatedStorage:WaitForChild("Getters")
local Remotes 		= ReplicatedStorage:WaitForChild("Remotes")
local Utility		= ReplicatedStorage:WaitForChild("Utility")
local Trackers		= ReplicatedStorage:WaitForChild("Trackers")

-- Module Scripts
local HighlightClosestShop	= require(Utility:WaitForChild("HighlightClosestShop"))
local teleportPlayer 		= require(Utility:WaitForChild("teleportPlayer"))
local localPlayerDetails	= require(Trackers:WaitForChild("localPlayerDetails"))

-- Local Player
local localPlayer 			= Players.LocalPlayer

-- GUI Elements
local playerGui 			= localPlayer.PlayerGui
local MainHUD 				= playerGui:WaitForChild("MainHUD")
local ShopButtons 			= MainHUD:WaitForChild("ShopButtons")
local CloseShopButton 		= ShopButtons:WaitForChild("CloseShopButton")
local GoToShopButton 		= ShopButtons:WaitForChild("GoToShopButton")
local EditShopButton 		= ShopButtons:WaitForChild("EditShopButton")

-- Remotes | Bindables
local PlayerEnteredOwnShopAsync	= Remotes:WaitForChild("PlayerEnteredOwnShop")
local PlayerExitedShopAsync	= Remotes:WaitForChild("PlayerExitedShop")

-- Variables
local pointing = nil

-- Functions
local function showEditButton()
	EditShopButton.Visible = true
end

local function hideEditButton()
	EditShopButton.Visible = false
end

local function showTeleportButton()
	GoToShopButton.Visible = true
end

local function hideTeleportButton()
	GoToShopButton.Visible = false
end

-- Runs when a player enters their own shop
local function onPlayerEnteredOwnShop()
	showEditButton()
	hideTeleportButton()
end

-- Runs when a player leaves their own shop
local function onPlayerExitedShop()
	hideEditButton()
	showTeleportButton()
end

-- Teleports player to shop if they have one, points them towards the closest one to claim if they don't
local function onGoToShopButtonPressed()
	
	if localPlayerDetails.playerHasShop() then
		print("Teleporting player")
		local playerShop = localPlayerDetails.getShopInstance()
		teleportPlayer(localPlayer, playerShop)
	else
		print("Player has no shop")
		if pointing then return end
		pointing = true
		
		HighlightClosestShop(localPlayer)
		
		pointing = false
	end
end

PlayerEnteredOwnShopAsync.OnClientEvent:Connect(onPlayerEnteredOwnShop)
PlayerExitedShopAsync.OnClientEvent:Connect(onPlayerExitedShop)
GoToShopButton.Activated:Connect(onGoToShopButtonPressed)