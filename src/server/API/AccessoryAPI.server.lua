--!strict

--[[
	Mannequins - This script handles loading in mannequin appearances. Mannequins have a list of accessory and bundle IDs
	set as attributes, which are used to customize the mannequin appearance.

	To create a mannequin rig, a new HumanoidDescription is created, the bundles and accessories are applied, and then
	Players:CreateHumanoidModelFromDescription() is used for the final creation.
--]]

-- Services
local ReplicatedStorage 			= game:GetService("ReplicatedStorage")

-- Folders
local Remotes     			= ReplicatedStorage:WaitForChild("Remotes")
local Utility 				= ReplicatedStorage:WaitForChild("Utility")
local Trackers 				= ReplicatedStorage:WaitForChild("Trackers")

-- Module Scripts
local ShopTracker 					= require(Trackers:WaitForChild("ShopTracker"))
local Types 						= require(Utility:WaitForChild("Types"))

-- Remotes / Bindables
local AddAccessoryEvent				= Remotes:WaitForChild("AddAccessory")
local DeleteAccessoryEvent			= Remotes:WaitForChild("DeleteAccessory")

--

local function removeAccessory(player: Player, accessoryId: number, mannequinId: number)
	local shopDetails = ShopTracker.getShopFromPlayer(player)

	if not shopDetails then
		assert(shopDetails, "player has no shop details!")
		return nil
	end

	local mannequin = shopDetails:getShopItemFromItemId(mannequinId) :: Types.BaseMannequin
	if not mannequin then  
		warn("No mannequin found for provided ID")
		return
	end

	mannequin:removeAccessory(accessoryId) 
	if not mannequin:isAccessoryEquipped(accessoryId) then
		return true
	else
		return false
	end
end

local function addAccessory(player: Player, accessoryId: number, mannequinId: number) : boolean
	local shopDetails = ShopTracker.getShopFromPlayer(player)
	if not shopDetails then
		assert(shopDetails, "player has no shop details!")
		return false
	end
	
	local mannequin = shopDetails:getShopItemFromItemId(mannequinId) :: Types.BaseMannequin
	if not mannequin then  
		warn("No mannequin found for provided ID")
		return false
	end
	
	mannequin:addAccessory(accessoryId) 
	if mannequin:isAccessoryEquipped(accessoryId) then
		return true
	else
		return false
	end
end

-- Connections
AddAccessoryEvent.OnServerInvoke = addAccessory
DeleteAccessoryEvent.OnServerInvoke = removeAccessory