--!strict
--[[
	AssetFilterCategories
	These are the main categories that can be sorted by in catalog searches.
	Each category has a display name, asset type enum, and description.
]]

type CategoryInfo = {
	name: string,
	assetType: Enum.AvatarAssetType,
	description: string
}

local AssetFilterCategories = {
	-- Classic Clothing
	{
		name = "T-Shirts",
		assetType = Enum.AvatarAssetType.TShirt,
		description = "Classic 2D T-Shirts"
	},
	{
		name = "Shirts",
		assetType = Enum.AvatarAssetType.Shirt,
		description = "Classic 2D shirts"
	},
	{
		name = "Pants",
		assetType = Enum.AvatarAssetType.Pants,
		description = "Classic 2D pants"
	},

	-- Body Parts
	{
		name = "Heads",
		assetType = Enum.AvatarAssetType.Head,
		description = "Avatar heads"
	},
	{
		name = "Faces",
		assetType = Enum.AvatarAssetType.Face,
		description = "Avatar faces"
	},

	-- Accessories
	{
		name = "Hats",
		assetType = Enum.AvatarAssetType.Hat,
		description = "Head accessories and hats"
	},
	{
		name = "Hair",
		assetType = Enum.AvatarAssetType.HairAccessory,
		description = "Hair accessories"
	},
	{
		name = "Face Accessories",
		assetType = Enum.AvatarAssetType.FaceAccessory,
		description = "Face accessories"
	},
	{
		name = "Neck Accessories",
		assetType = Enum.AvatarAssetType.NeckAccessory,
		description = "Neck accessories"
	},
	{
		name = "Shoulder Accessories",
		assetType = Enum.AvatarAssetType.ShoulderAccessory,
		description = "Shoulder accessories"
	},
	{
		name = "Front Accessories",
		assetType = Enum.AvatarAssetType.FrontAccessory,
		description = "Front accessories"
	},
	{
		name = "Back Accessories",
		assetType = Enum.AvatarAssetType.BackAccessory,
		description = "Back accessories"
	},
	{
		name = "Waist Accessories",
		assetType = Enum.AvatarAssetType.WaistAccessory,
		description = "Waist accessories"
	},

	-- Layered Clothing
	{
		name = "Layered T-Shirts",
		assetType = Enum.AvatarAssetType.TShirtAccessory,
		description = "Layered clothing T-Shirts"
	},
	{
		name = "Layered Shirts",
		assetType = Enum.AvatarAssetType.ShirtAccessory,
		description = "Layered clothing shirts"
	},
	{
		name = "Layered Pants",
		assetType = Enum.AvatarAssetType.PantsAccessory,
		description = "Layered clothing pants"
	},
	{
		name = "Jackets",
		assetType = Enum.AvatarAssetType.JacketAccessory,
		description = "Layered clothing jackets"
	},
	{
		name = "Sweaters",
		assetType = Enum.AvatarAssetType.SweaterAccessory,
		description = "Layered clothing sweaters"
	},
	{
		name = "Shorts",
		assetType = Enum.AvatarAssetType.ShortsAccessory,
		description = "Layered clothing shorts"
	},
	{
		name = "Dresses & Skirts",
		assetType = Enum.AvatarAssetType.DressSkirtAccessory,
		description = "Layered clothing dresses and skirts"
	}
}

-- Helper function to get category names for dropdown
function AssetFilterCategories.getCategoryNames(): {string}
	local names = {"All"} -- Add "All" option first

	for _, category in ipairs(AssetFilterCategories) do
		table.insert(names, category.name)
	end

	return names
end

-- Helper function to get category by name
function AssetFilterCategories.getCategoryByName(name: string): CategoryInfo?
	if name == "All" then
		return nil -- No filtering for "All"
	end

	for _, category in ipairs(AssetFilterCategories) do
		if category.name == name then
			return category
		end
	end

	return nil
end

function AssetFilterCategories.getCategoriesByName(names: {string}): {CategoryInfo}
	local categories = {}

	for _, category in ipairs(AssetFilterCategories) do
		if table.find(names, category.name) then
			table.insert(categories, category)
		end
	end

	return categories
end

-- Helper function to get asset type enum by category name
function AssetFilterCategories.getAssetType(categoryName: string): Enum.AvatarAssetType?
	local category = AssetFilterCategories.getCategoryByName(categoryName)
	return category and category.assetType
end

-- Helper function to get all asset type enums
function AssetFilterCategories.getAllAssetTypes(): {Enum.AvatarAssetType}
	local assetTypes = {}
	for _, category in ipairs(AssetFilterCategories) do
		table.insert(assetTypes, category.assetType)
	end
	return assetTypes
end

-- Export the type for external use
export type CategoryInfo = CategoryInfo

return AssetFilterCategories