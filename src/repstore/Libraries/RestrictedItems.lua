--!strict

--[[
	RestrictedItems - This module contains a list of restricted items which are not able to
	be sold through the normal purchase and bulk purchase remotes. This should be used in cases
	where a free UGC item is being given out through a game mechanic or similar.

	This prevents exploiters from being able to fire the purchase remotes to arbitrarily to claim the item.
--]]

export type RestrictedItem = {
	id: number,
	type: Enum.MarketplaceProductType,
}

local RESTRICTED_ITEMS: { RestrictedItem } = {
	-- { id = 00000, type = Enum.MarketplaceProductType.AvatarAsset }
}

local RestrictedItems = {}

function RestrictedItems.isRestricted(itemId: number, itemType: Enum.MarketplaceProductType): boolean
	for _, item in RESTRICTED_ITEMS do
		if item.id == itemId and item.type == itemType then
			return true
		end
	end

	return false
end

return RestrictedItems
