--[[
	Server Placer
]]

--!strict


--[[
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local TweenService		= game:GetService("TweenService")

-- Folders
local Bindables	= ReplicatedStorage:WaitForChild("Bindables")
local Templates	= ReplicatedStorage:WaitForChild("Templates")
local Trackers 	= ReplicatedStorage:WaitForChild("Trackers")
local Utility	= ReplicatedStorage:WaitForChild("Utility")
local Getters	= ReplicatedStorage:WaitForChild("Getters")
local Remotes 	= ReplicatedStorage:WaitForChild("Remotes")


-- Remotes | Bindables
local PlayerPlacedShopItemAsync = Remotes:WaitForChild("PlayerPlacedShopItem")
local RepositionShopItemAsync 	= Remotes:WaitForChild("RepositionShopItem")
local SetupMannequinFunction	= Bindables:WaitForChild("SetupMannequin")
local NudgeShopItemAsync		= Remotes:WaitForChild("NudgeShopItem")

-- Templates
local mannequinTemplate  	 	= Templates:WaitForChild("FullMannequin")

-- Module Scripts
local getMannequinFromId 		= require(Getters:WaitForChild("getMannequinFromId"))
local getFurnitureFromId 		= require(Getters:WaitForChild("getFurnitureFromId"))
local Constants 				= require(ReplicatedStorage:WaitForChild("Constants"))	
local SerialisationUtilities 	= require(Utility:WaitForChild("SerialisationUtilities"))
local getGroundYFromRay 		= require(Utility:WaitForChild("getGroundYFromRay"))
local getRandomIdNumber 			= require(Utility:WaitForChild("getRandomIdNumber"))
local Types 			 		= require(Utility:WaitForChild("Types"))
local ShopTracker				= require(Trackers:WaitForChild("ShopTracker"))
local PlayerTracker 			= require(Trackers:WaitForChild("PlayerTracker"))

local serialiseVector    		= SerialisationUtilities.serialiseVector
local unserialiseVector  		= SerialisationUtilities.unserialiseVector
local serialiseCFrame	  		= SerialisationUtilities.serialiseCFrame
local unserialiseCFrame  		= SerialisationUtilities.unserialiseCFrame

-- Remotes | Bindables
local DeleteShopItemEvent		= Remotes:WaitForChild("DeleteShopItem")
local UserKeyPressed 			= Remotes:WaitForChild("UserKeyPressed")

-- Datastores
local playerShopsDataStore		= DataStoreService:GetDataStore(Constants.PLAYER_SHOPS_DATA_STORE_NAME)
local ownedItemsDataStore		= DataStoreService:GetDataStore(Constants.OWNEDITEMS_DATASTORE)

-- Variables
local shopsArray 			= {}

-- Local Constants
local defaultNudge 			= 1
local defaultRotate 		= 45
local placingObject 		= false
local NUDGE_TWEEN_DURATION 	= 0.2

-- Destroys a mannequin
local function destroyShopItem(plr: Player, mannequinId: string)
	local item = getFurnitureFromId(plr, mannequinId) 
	if item then item:Destroy() end
end


-- Removes a mannequin from a player store
-- TODO - rename this to removeShopItemFromPlayerStore
local function deleteShopItem(player: Player, itemId: string)
	local playerShop = ShopTracker.getShopFromPlayer(player)
	if not playerShop then
		return
	end
	
	playerShop:removeShopItem(itemId)
end

local function nudgeItem(player: Player, itemId: number, direction: string)
	-- Don't allow nudging if already nudging
	local playerShop = ShopTracker.getShopFromPlayer(player)
	if not playerShop then 
		warn("No player shop at nudge!")
		return
	end
	 
	local shopItem = playerShop:getShopItemFromItemId(itemId)
	if not shopItem then
		warn("No item found for ID")
		return
	end
	shopItem:nudge(direction)
end



local function repositionShopItem(player: Player, accessoryId: number, newCFrame: {})
	-- Don't allow nudging if already nudging
	local playerShop = ShopTracker.getShopFromPlayer(player)
	if not playerShop then 
		warn("No player shop at nudge!")
		return
	end

	local shopItem = playerShop:getShopItemFromItemId(accessoryId)
	if not shopItem then
		warn("No item found for ID")
		return 
	end
	
	newCFrame = SerialisationUtilities.unserialiseCFrame(newCFrame)
	shopItem:Reposition(newCFrame)
end


-- Runs the relevant function for placing a given object
local function placeShopItem(player: Player, shopItemRecipe : Types.ShopItemRecipe)
	if placingObject then 
		warn("Placing object already!") 
		return 
	end
	placingObject = true

	local playerShop = ShopTracker.getShopFromPlayer(player)
	if not playerShop then
		warn("No player shop found at placements")
	else
		playerShop:addShopItem(shopItemRecipe)
	end  
	
	placingObject = false

end


-- TODO: This is for debugging and must be removed on launch
-- USERKEY HERE
-- DELETE FUNCTION HERE
local function onKeyPress(plr: Player, input: number)
	if input == Enum.KeyCode.P.Value then
		-- Wipe the player's datastore
		playerShopsDataStore:SetAsync(plr.UserId, {})
		print(playerShopsDataStore:GetAsync(plr.UserId))
	elseif input == Enum.KeyCode.O.Value then
		print(playerShopsDataStore:GetAsync(plr.UserId))
	elseif input == Enum.KeyCode.K.Value then
		print(ownedItemsDataStore:GetAsync(tostring(plr.UserId)))
	elseif input == Enum.KeyCode.L.Value then
		ownedItemsDataStore:SetAsync(plr.UserId, {})
		print(ownedItemsDataStore:GetAsync(tostring(plr.UserId)))
	end
end

RepositionShopItemAsync.OnServerEvent:Connect(repositionShopItem)
PlayerPlacedShopItemAsync.OnServerEvent:Connect(placeShopItem)
DeleteShopItemEvent.OnServerEvent:Connect(deleteShopItem)
NudgeShopItemAsync.OnServerEvent:Connect(nudgeItem)
UserKeyPressed.OnServerEvent:Connect(onKeyPress)
]]