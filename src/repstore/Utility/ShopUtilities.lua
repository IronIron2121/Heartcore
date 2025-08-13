--!strict

-- Services
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")
local DataStoreService 			= game:GetService("DataStoreService")

-- Folders
local BindablesFolder			= ReplicatedStorage:WaitForChild("Bindables")
local TemplatesFolder 			= ReplicatedStorage:WaitForChild("Templates")
local TexturesFolder 			= ReplicatedStorage:WaitForChild("Textures")
local UtilityFolder 			= ReplicatedStorage:WaitForChild("Utility")
local GettersFolder				= ReplicatedStorage:WaitForChild("Getters")

-- Templates
local mannequinTemplate 		= TemplatesFolder:WaitForChild("FullMannequin")

-- Utilities / Module Scripts
local getFurnitureFromId 		= require(GettersFolder:WaitForChild("getFurnitureFromId"))
local SerialisationUtilities	= require(UtilityFolder:WaitForChild("SerialisationUtilities"))
local serialiseAttributes 		= SerialisationUtilities.serialiseAttributes
local unserialiseCFrame   		= SerialisationUtilities.unserialiseCFrame
local serialiseCFrame   		= SerialisationUtilities.serialiseCFrame

local Types 					= require(UtilityFolder:WaitForChild("Types"))
local Constants					= require(ReplicatedStorage:WaitForChild("Constants")) 


local getRelativePosition 		= require(UtilityFolder:WaitForChild("getRelativePosition"))

-- Datastores
local playerShopsDataStore 	= DataStoreService:GetDataStore(Constants.PLAYER_SHOPS_DATA_STORE_NAME)

type mannequinTemplate = Model & {
	Base: Part,
	Placeholder: MeshPart
}

local shopUtilities = {}

function shopUtilities.changeItemColour(player: Player, colour: string, furnitureId: string): boolean?
	if colour == "Default" then
		return true
	end
	local furniture = getFurnitureFromId(player,furnitureId)
	if not furniture then
		warn("Furniture not found for ID ", furnitureId, player)
		return nil
	end
	local thisTexture = TexturesFolder[colour] :: SurfaceAppearance? 
	if not thisTexture then
		warn("No colour for ", colour)
		return nil
	end
	local applyTexture = thisTexture:Clone()
	for _, child in pairs(furniture:GetChildren()) do
		if child:IsA("MeshPart") then
			child:ClearAllChildren()
			applyTexture:Clone().Parent = child
		end
	end
	furniture:SetAttribute(Constants.ITEM_COLOUR_ATTRIBUTE, colour)
	shopUtilities.saveItem(player, furniture)
	return true
end



-- Creates a serialised table
local function createItemTable(item: Model, itemType: string, player: Player): {}?
	-- Calculate mannequin's position relative to player's shop
	local playerShop = getShopFromPlayer(player)
	if not playerShop then return nil end
	
	local relativeItemCFrame = getRelativePosition(playerShop.CFrame, item:GetPivot())
	
	local itemAttributes = serialiseAttributes(item:GetAttributes())
	itemAttributes["skinColor"] = nil
	
	local itemTable = {
		itemCFrame = serialiseCFrame(relativeItemCFrame),
		itemAttributes = itemAttributes,
		itemType = itemType,
		itemName = item.Name
	}
	
	return itemTable
end



return shopUtilities
