--!strict

--[[
	getBundleCategory - A utility function to get the overall category type of a bundle
--]]

local CATEGORY_MAPPING = {
	[Enum.BundleType.BodyParts] = "Body",
	[Enum.BundleType.DynamicHead] = "Body",
}

local function getBundleCategory(bundleType: Enum.BundleType): string
	return CATEGORY_MAPPING[bundleType] or bundleType.Name
end

return getBundleCategory
