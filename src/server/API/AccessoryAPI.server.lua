--!strict

--[[
	Mannequins - This script handles loading in mannequin appearances. Mannequins have a list of accessory and bundle IDs
	set as attributes, which are used to customize the mannequin appearance.

	To create a mannequin rig, a new HumanoidDescription is created, the bundles and accessories are applied, and then
	Players:CreateHumanoidModelFromDescription() is used for the final creation.
--]]

-- Services
local MarketplaceService 			= game:GetService("MarketplaceService")
local ReplicatedStorage 			= game:GetService("ReplicatedStorage")
local CollectionService 			= game:GetService("CollectionService")
local DataStoreService 				= game:GetService("DataStoreService")
local InsertService					= game:GetService("InsertService")
local ServerStorage 				= game:GetService("ServerStorage")
local Players 						= game:GetService("Players")

-- Folders
local Templates				= ReplicatedStorage:WaitForChild("Templates")
local Libraries				= ReplicatedStorage:WaitForChild("Libraries")
local Bindables 			= ReplicatedStorage:WaitForChild("Bindables")
local Checkers				= ReplicatedStorage:WaitForChild("Checkers")
local Remotes     			= ReplicatedStorage:WaitForChild("Remotes")
local Utility 				= ReplicatedStorage:WaitForChild("Utility")
local Getters				= ReplicatedStorage:WaitForChild("Getters")
local Trackers 				= ReplicatedStorage:WaitForChild("Trackers")


-- Templates
local MannequinTemplate 			= Templates:WaitForChild("FullMannequin")

-- Module Scripts
local applyItemsToDescriptionAsync 	= require(Utility:WaitForChild("applyItemsToDescriptionAsync"))
local setDescriptionSkinColor 		= require(Utility:WaitForChild("setDescriptionSkinColor"))
local stringOfNumbersToArray 		= require(Utility:WaitForChild("stringOfNumbersToArray")) 
local arrayOfNumbersToString 		= require(Utility:WaitForChild("arrayOfNumbersToString"))
local getRandomIdNumber 			= require(Utility:WaitForChild("getRandomIdNumber"))
local PlayerTracker					= require(Trackers:WaitForChild("PlayerTracker"))
local ShopTracker 					= require(Trackers:WaitForChild("ShopTracker"))
local Types 						= require(Utility:WaitForChild("Types"))

-- Module Script
local Constants 					= require(ReplicatedStorage:WaitForChild("Constants")) 
local getMannequinFromId 			= require(Getters:WaitForChild("getMannequinFromId"))

-- Datastores
local playerShopsDataStore 		    = DataStoreService:GetDataStore(Constants.PLAYER_SHOPS_DATA_STORE_NAME)

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