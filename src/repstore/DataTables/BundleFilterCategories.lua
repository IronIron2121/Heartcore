--!strict
--[[
BundleFilterCategories
These are the main bundle types that can be sorted by in catalog searches.
Each bundle type has a display name, bundle type ID, and description.
]]

type BundleTypeInfo = {
	name: string,
	bundleType: Enum.BundleType,
	description: string
}

local BundleFilterCategories = {
	{
		name = "Body Parts",
		bundleType = Enum.BundleType.BodyParts,
		description = "A bundle of body parts and accessories"
	},
	{
		name = "Animations",
		bundleType = Enum.BundleType.Animations,
		description = "A bundle of just animations"
	},
	{
		name = "Shoes",
		bundleType = Enum.BundleType.Shoes,
		description = "A bundle of left shoe and right shoe"
	},
	{
		name = "Dynamic Head",
		bundleType = Enum.BundleType.DynamicHead,
		description = "A bundle consisting of dynamicHead and moodAnimation assets, optionally with eyebrowAccessory and eyelashAccessory"
	},
	{
		name = "Dynamic Head Avatar",
		bundleType = Enum.BundleType.DynamicHeadAvatar,
		description = "A complete dynamic head avatar bundle"
	}
}

-- Helper function to get bundle type names for dropdown
function BundleFilterCategories.getBundleTypeNames(): {string}
	local names = {"All"} -- Add "All" option first
	for _, bundleType in ipairs(BundleFilterCategories) do
		table.insert(names, bundleType.name)
	end
	return names
end

-- Helper function to get bundle type by name
function BundleFilterCategories.getBundleTypeByName(name: string): BundleTypeInfo?
	if name == "All" then
		return nil -- No filtering for "All"
	end
	for _, bundleType in ipairs(BundleFilterCategories) do
		if bundleType.name == name then
			return bundleType
		end
	end
	return nil
end

-- Helper function to get bundle type ID by name
function BundleFilterCategories.getBundleTypeId(bundleTypeName: string): number?
	local bundleType = BundleFilterCategories.getBundleTypeByName(bundleTypeName)
	return bundleType and bundleType.bundleType.Value
end

-- Helper function to get Roblox enum equivalent
function BundleFilterCategories.getRobloxBundleType(bundleTypeName: string): Enum.BundleType?
	local bundleType = BundleFilterCategories.getBundleTypeByName(bundleTypeName)
	return bundleType and bundleType.bundleType
end

-- Helper function to get all Roblox bundle type enums
function BundleFilterCategories.getAllRobloxBundleTypes(): {Enum.BundleType}
	local bundleTypes = {}
	
	for _, bundleType in ipairs(BundleFilterCategories) do
		table.insert(bundleTypes, bundleType.bundleType)
	end
	return bundleTypes
end

-- Helper function to get all Roblox bundle type enums
function BundleFilterCategories.getAllRobloxBundleSearchTypes(): {Enum.BundleType}
	local bundleTypes = {}
	
	for _, bundleType in ipairs(BundleFilterCategories) do
		if bundleType.name ~= "Animations" then
			table.insert(bundleTypes, bundleType.bundleType)
		end
	end

	return bundleTypes
end

-- Export the type for external use
export type BundleTypeInfo = BundleTypeInfo

return BundleFilterCategories