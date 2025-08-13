--!strict

--[[
	getItemCategory - A utility function to get the overall category type of an accessory
--]]

local CATEGORY_MAPPING = {
	[Enum.AccessoryType.TShirt] = "Top",
	[Enum.AccessoryType.Shirt] = "Top",
	[Enum.AccessoryType.Sweater] = "Top",
	[Enum.AccessoryType.Pants] = "Bottom",
	[Enum.AccessoryType.Shorts] = "Bottom",
	[Enum.AccessoryType.DressSkirt] = "Bottom",
}

local function getAccessoryCategory(accessoryType: Enum.AccessoryType): string
	return CATEGORY_MAPPING[accessoryType] or accessoryType.Name
end

return getAccessoryCategory
