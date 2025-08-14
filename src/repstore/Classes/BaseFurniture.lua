--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Templates = ReplicatedStorage:WaitForChild("Templates")
local FurnitureTemplates = Templates:WaitForChild("Furniture")
local Classes = ReplicatedStorage:WaitForChild("Classes")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local BaseShopItem = require(Classes:WaitForChild("BaseShopItem"))
local Types = require(Utility:WaitForChild("Types"))
local SerialisationUtilities = require(Utility:WaitForChild("SerialisationUtilities"))
local unserialiseCFrame = SerialisationUtilities.unserialiseCFrame

local BaseFurniture = setmetatable({}, BaseShopItem)
BaseFurniture.__index = BaseFurniture

function BaseFurniture.new(shopItemRecipe : Types.ShopItemRecipe)
	local newBaseFurniture = BaseShopItem.new(shopItemRecipe) :: Types.BaseFurniture
	setmetatable(newBaseFurniture, BaseFurniture)
	
	newBaseFurniture.instance = BaseFurniture.initialiseInstance(shopItemRecipe)
	
	return newBaseFurniture 
end

function BaseFurniture.initialiseInstance(shopItemRecipe : Types.ShopItemRecipe) : Model?

	local instance = FurnitureTemplates:WaitForChild(shopItemRecipe.itemName):Clone() :: Model

	if not instance then
		return nil
	else
		instance:PivotTo(unserialiseCFrame(shopItemRecipe.itemCFrame))
		return instance
	end
end

return BaseFurniture