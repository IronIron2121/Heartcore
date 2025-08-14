--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Classes = ReplicatedStorage:WaitForChild("Classes")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local HeadMannequin = require(Classes:WaitForChild("HeadMannequin"))
local FullMannequin = require(Classes:WaitForChild("FullMannequin"))
local Mannequin = require(Classes:WaitForChild("FullMannequin"))
local Types = require(Utility:WaitForChild("Types"))

local MannequinFactory = {}

function MannequinFactory.createMannequin(shopItemRecipe : Types.ShopItemRecipe) : Types.BaseShopItem?
	if shopItemRecipe.itemName == Constants.FULL_MANNEQUIN_NAME then
		return FullMannequin.new(shopItemRecipe) 
	elseif shopItemRecipe.itemName == Constants.HEAD_MANNEQUIN_NAME then
		return HeadMannequin.new(shopItemRecipe)
	else
		warn("No mannequin for this item name!")
		return nil
	end
end

return MannequinFactory