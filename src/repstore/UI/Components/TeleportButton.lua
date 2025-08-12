--!strict

--[[
	TeleportButton - This function acts as a basic UI component, creating a button that teleports players to shops

	This is used for the PlayerClick UI
--]]

local ReplicatedStorage 	  	= game:GetService("ReplicatedStorage")

local GettersFolder 			= ReplicatedStorage:WaitForChild("Getters")
local UtilityFolder				= ReplicatedStorage:WaitForChild("Utility")
local UIFolder 				  	= ReplicatedStorage:WaitForChild("UI")
local ObjectsFolder 		  	= UIFolder:WaitForChild("Objects")

local teleportButtonTemplate  	= ObjectsFolder:WaitForChild("TeleportButton")

local getPlayerFromPlayerName 	= require(GettersFolder:WaitForChild("getPlayerFromPlayerName"))
local teleportPlayer 			= require(UtilityFolder:WaitForChild("teleportPlayer"))
local Constants				  	= require(ReplicatedStorage:WaitForChild("Constants"))

local function TeleportButton(clickingPlayer: Player, clickedPlayer: Player): TextButton?	
	if not clickedPlayer then 
		warn("No player found")
		return nil 
	end
	
	local plrShop = getShopFromPlayer(clickedPlayer)
	
	if not plrShop then 
		warn(clickedPlayer.Name .. " has no shop")
		return nil 
	end

	local teleportButton = teleportButtonTemplate:Clone()
	teleportButton.Text = "Teleport to " .. clickedPlayer.Name .. "'s Shop"
	teleportButton.Activated:Connect(function()
		teleportPlayer(clickingPlayer, plrShop)
	end)
	
	return teleportButton
end

return TeleportButton