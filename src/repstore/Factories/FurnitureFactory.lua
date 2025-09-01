--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Classes = ReplicatedStorage:WaitForChild("Classes")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(Utility:WaitForChild("Types"))
local BaseFurniture = require(Classes:WaitForChild("BaseFurniture"))

local FurnitureFactory = {}

function FurnitureFactory.createFurniture(shopItemRecipe : Types.ShopItemRecipe) : Types.BaseShopItem?
	if shopItemRecipe.itemType == Constants.FURNITURE_ITEM_TYPE then
		return BaseFurniture.new(shopItemRecipe) 
	else
		warn("No Furniture for this item name!")
		return nil
	end
end

return FurnitureFactory