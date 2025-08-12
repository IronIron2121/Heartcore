--!strict

--[[
	This functions returns a mannequin instance from the workspace given an ID number
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GettersFolder 	= ReplicatedStorage:WaitForChild("Getters")
local UtilityFolder 	= ReplicatedStorage:WaitForChild("Utility")
local Trackers 			= ReplicatedStorage:WaitForChild("Trackers")


-- Modules
local Constants 		= require(ReplicatedStorage:WaitForChild("Constants"))
local PlayerTracker		= require(Trackers:WaitForChild("PlayerTracker"))
local ShopTracker 		= require(Trackers:WaitForChild("ShopTracker"))
local Types 			= require(UtilityFolder:WaitForChild("Types"))

-- TODO: Fix this type error
function getFurnitureFromId(player: Player, targetId: string): Model?
	local plrShop = ShopTracker.getShopFromPlayer(player)
	if not plrShop then return end
	
	return plrShop:getShopItemFromItemId(targetId)
end
 
return getFurnitureFromId
