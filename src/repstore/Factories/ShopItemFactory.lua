--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Factories = ReplicatedStorage:WaitForChild("Factories")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(Utility:WaitForChild("Types"))
local MannequinFactory = require(Factories:WaitForChild("MannequinFactory"))
local FurnitureFactory = require(Factories:WaitForChild("FurnitureFactory"))

local ShopItemFactory = {}

function ShopItemFactory.createShopItem(shopItemRecipe : Types.ShopItemRecipe) : Types.BaseShopItem
	if shopItemRecipe.itemType == Constants.MANNEQUIN_ITEM_TYPE then
		return MannequinFactory.createMannequin(shopItemRecipe)
	elseif shopItemRecipe.itemType == Constants.FURNITURE_ITEM_TYPE then
		return FurnitureFactory.createFurniture(shopItemRecipe)
	else
		warn("No factory for item ", shopItemRecipe.itemType)
	end
		
end

return ShopItemFactory