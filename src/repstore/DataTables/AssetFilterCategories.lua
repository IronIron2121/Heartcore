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

local CLASSIC_CLOTHING = {Enum.AvatarAssetType.TShirt, Enum.AvatarAssetType.Shirt, Enum.AvatarAssetType.Pants}

local SEARCH_ACCESSORIES = {
	Enum.AvatarAssetType.FaceAccessory,
	Enum.AvatarAssetType.NeckAccessory,
	Enum.AvatarAssetType.ShoulderAccessory,
	Enum.AvatarAssetType.FrontAccessory,
	Enum.AvatarAssetType.BackAccessory,
	Enum.AvatarAssetType.WaistAccessory,
	Enum.AvatarAssetType.TShirtAccessory,
	Enum.AvatarAssetType.ShirtAccessory,
	Enum.AvatarAssetType.PantsAccessory,
	Enum.AvatarAssetType.JacketAccessory,
	Enum.AvatarAssetType.SweaterAccessory,
	Enum.AvatarAssetType.ShortsAccessory,
	Enum.AvatarAssetType.DressSkirtAccessory,

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
		name = "Face",
		assetType = Enum.AvatarAssetType.FaceAccessory,
		description = "Face accessories"
	},
	{
		name = "Neck",
		assetType = Enum.AvatarAssetType.NeckAccessory,
		description = "Neck accessories"
	},
	{
		name = "Shoulder",
		assetType = Enum.AvatarAssetType.ShoulderAccessory,
		description = "Shoulder accessories"
	},
	{
		name = "Front",
		assetType = Enum.AvatarAssetType.FrontAccessory,
		description = "Front accessories"
	},
	{
		name = "Back",
		assetType = Enum.AvatarAssetType.BackAccessory,
		description = "Back accessories"
	},
	{
		name = "Waist",
		assetType = Enum.AvatarAssetType.WaistAccessory,
		description = "Waist accessories"
	},
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

function AssetFilterCategories.getCategoryInfoFromAssetType(assetType: Enum.AvatarAssetType): CategoryInfo?
	for _, categoryInfo in ipairs(AssetFilterCategories) do
		if categoryInfo.assetType == assetType then
			return categoryInfo
		end
	end
	warn("Could not find category corresponding to assetType", assetType, "!")
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


-- Helper function to get all asset type enums
function AssetFilterCategories.getAllAssetSearchTypes(): {CategoryInfo}
	local assetTypes = {}
	for _, category in ipairs(AssetFilterCategories) do
		if table.find(SEARCH_ACCESSORIES, category.assetType)  then
			table.insert(assetTypes, category)
		end
	end
	return assetTypes
end

-- Helper function to get all asset type enums
function AssetFilterCategories.getAllClassicAssetSearchTypes(): {CategoryInfo}
	local assetTypes = {}
	for _, category in ipairs(AssetFilterCategories) do
		if table.find(CLASSIC_CLOTHING, category.assetType)  then
			table.insert(assetTypes, category)
		end
	end
	return assetTypes
end

-- Export the type for external use
export type CategoryInfo = CategoryInfo

return AssetFilterCategories