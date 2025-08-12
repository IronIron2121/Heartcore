-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Templates	= ReplicatedStorage:WaitForChild("Templates")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local FurnitureTemplates = Templates:WaitForChild("Furniture")

-- Templates
local FullMannequinTemplate	= Templates:WaitForChild("FullMannequin")
local HeadMannequinTemplate = Templates:WaitForChild("HeadMannequin")
local BinTemplate			= FurnitureTemplates:WaitForChild("Bin")

-- Module Scripts
local FurnitureColours = require(DataTables:WaitForChild("FurnitureColours"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

export type BuyableShopItems = {
	Name : string,
	ItemType : string,
	Price : string,
	Template : Model?,
	ThumbnailId : string,
	Colours : {string},
	Description : string,
	Tags : {string}
	
}

-- TODO: Maybe make this a 1-level dictionary?
local BuyableShopItems = {
	FullMannequin = {
		Name = "FullMannequin",
		ItemType = Constants.MANNEQUIN_ITEM_TYPE,
		Price = "Free",
		Template = Templates:WaitForChild("FullMannequin"),
		ThumbnailId = "101253324704442",
		Colours = {"Kitty"},
		Description = "A full-body mannequin, able to equip all accessories and bundles",
		Tags = {"Mannequin"},
	},

	HeadMannequin = {
		Name = "HeadMannequin",
		Price = "Free",
		ItemType = Constants.MANNEQUIN_ITEM_TYPE,
		Template = Templates:WaitForChild("HeadMannequin"),
		Colours = {"Kitty"},
		Description = "A head mannequin, able to equip all head and neck accessories",
		Tags = {"Mannequin", "New"}
	},

	Bin = {
		Name = "Bin",
		Price = "Free",
		ItemType = Constants.FURNITURE_ITEM_TYPE,
		Template = FurnitureTemplates:WaitForChild("Bin"),
		Colours = {"Kitty"},
		Description = "For all your waste disposal needs",
		Tags = {"Furniture", "New"}
	},

	Shelf = {
		Name = "Shelf",
		Price = "Free",
		ItemType = Constants.FURNITURE_ITEM_TYPE,
		Template = FurnitureTemplates:WaitForChild("Shelf"),
		Colours = {"Kitty", "Shrek"},
		Description = "Now where did I put those keys...?",
		Tags = {"Furniture", "New"},
	}, 

	Test = {
		Name = "Test",
		Price = "Free",
		ItemType = Constants.FURNITURE_ITEM_TYPE,
		Template = nil,
		Colours = {"Kitty"},
		Description = "Lorum ipsum",
		Tags = {"Floors"}
	},
}

return BuyableShopItems
