--!strict

--[[
	TryOn - This module implements the try on system, allowing the player to try various items on their character.
	This is a singleton intended only for use on the client, as the client keeps track of which items are being
	tried on and then notifies the server to update what the character is wearing.

	Events are created to notify other scripts when items are added or removed.
--]]

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.Settings)
local ItemDetailsCache = require(ReplicatedStorage.Libraries.ItemDetailsCache)
local ItemContainer = require(ReplicatedStorage.Utility.ItemContainer)
local getBundleCategory = require(ReplicatedStorage.Utility.getBundleCategory)
local getAccessoryCategory = require(ReplicatedStorage.Utility.getAccessoryCategory)

local remotes = ReplicatedStorage.Remotes
local tryOnRemote = remotes.TryOn

local container = ItemContainer.new()
local isAdding = false

local function updateWearing()
	local items = container:getItems()
	local assets = {}
	local bundles = {}

	for _, item in items do
		if item.type == Enum.MarketplaceProductType.AvatarAsset then
			table.insert(assets, item.id)
		elseif item.type == Enum.MarketplaceProductType.AvatarBundle then
			table.insert(bundles, item.id)
		end
	end

	tryOnRemote:FireServer(assets, bundles)
end

local TryOn = {
	itemAdded = container.itemAdded,
	itemRemoved = container.itemRemoved,
}

function TryOn.getItem(itemId: number, itemType: Enum.MarketplaceProductType): ItemContainer.ContainedItem?
	return container:getItem(itemId, itemType)
end

function TryOn.addItemAsync(itemId: number, itemType: Enum.MarketplaceProductType)
	if isAdding then
		return
	end

	isAdding = true

	-- Get either the asset category based on itemType to figure out the item's category
	local category
	if itemType == Enum.MarketplaceProductType.AvatarBundle then
		local bundleDetails = ItemDetailsCache.getBundleDetailsAsync(itemId)

		if bundleDetails then
			local bundleType = Enum.BundleType[bundleDetails.BundleType]
			category = getBundleCategory(bundleType)
		end
	else
		local assetDetails = ItemDetailsCache.getAssetDetailsAsync(itemId)

		if assetDetails then
			local assetType = Enum.AvatarAssetType[assetDetails.AssetType]
			local accessoryType = AvatarEditorService:GetAccessoryType(assetType)
			category = getAccessoryCategory(accessoryType)
		end
	end

	if not category then
		warn(`Failed to get category for {itemId}-{itemType}`)
		return
	end

	-- Remove similar items, with the exception of hats
	if category ~= "Hat" and category ~= "Unknown" then
		local items = container:getItems()
		for _, item in items do
			if item.data.category == category then
				container:removeItem(item.id, item.type)
			end
		end
	end

	-- Make sure we're not exceeding the try on limit
	if #container:getItems() < Settings.MAX_TRY_ON_ITEMS then
		container:addItem(itemId, itemType, { category = category })
	end
	isAdding = false


	updateWearing()
end

function TryOn.removeItem(itemId: number, itemType: Enum.MarketplaceProductType)
	container:removeItem(itemId, itemType)
	updateWearing()
end

function TryOn.setItemsAsync(items: { { id: number, type: Enum.MarketplaceProductType } })
	container:setItems(items)
	updateWearing()
end

function TryOn.getItems(): { ItemContainer.ContainedItem }
	return container:getItems()
end

return TryOn
