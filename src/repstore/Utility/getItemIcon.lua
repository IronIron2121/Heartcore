--!strict

--[[
	getItemIcon - A utility function to get the icon for an item, using the rbxthumb:// format.
	See: https://create.roblox.com/docs/projects/assets#asset-format-strings
--]]

local RESOLUTION = 150

local function getItemIcon(itemId: number, itemType: Enum.AvatarItemType | Enum.MarketplaceProductType): string
	if itemType == Enum.AvatarItemType.Asset or itemType == Enum.MarketplaceProductType.AvatarAsset then
		return `rbxthumb://type=Asset&id={itemId}&w={RESOLUTION}&h={RESOLUTION}`
	elseif itemType == Enum.AvatarItemType.Bundle or itemType == Enum.MarketplaceProductType.AvatarBundle then
		return `rbxthumb://type=BundleThumbnail&id={itemId}&w={RESOLUTION}&h={RESOLUTION}`
	else
		warn(`Invalid item type: {itemType}`)
		return ""
	end
end

return getItemIcon

-- I think that when we implement this in our own code we will squeeze some of these into one central script