--!strict

--[[
	Cart - This module implements the cart system, allowing items to be added to/removed from a virtual 'cart'.
	This is a singleton intended only for use on the client, as the client keeps track of which items are in the
	cart and then notifies the server when it would like to make a purchase.

	Events are created to notify other scripts when items are added or removed, and a utility function is provided
	to calculate the total cost of all items in the cart.

	Item details are fetched from the Item Details Cache and stored with each item so they can
	be easily referenced by the UI systems without making extra calls to the cache.
--]]

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDetailsCache = require(ReplicatedStorage.Libraries.ItemDetailsCache)
local Types = require(ReplicatedStorage.Utility.Types)
local ItemContainer = require(ReplicatedStorage.Utility.ItemContainer)

local remotes = ReplicatedStorage.Remotes
local bulkPurchaseRemote = remotes.BulkPurchase

-- MarketplaceService:PromptBulkPurchase() has a limit of 20
local MAX_ITEMS = 20

local container = ItemContainer.new()

local Cart = {
	itemAdded = container.itemAdded,
	itemRemoved = container.itemRemoved,
}



local function onBulkPurchaseFinished(
	_: Instance,
	status: Enum.MarketplaceBulkPurchasePromptStatus,
	result: Types.BulkPurchaseResult
)
	if status ~= Enum.MarketplaceBulkPurchasePromptStatus.Completed then
		return
	end

	-- Remove all the items that were successfully purchased from the cart
	for _, item in result.Items do
		if item.status ~= Enum.MarketplaceItemPurchaseStatus.Success then
			continue
		end

		local id = tonumber(item.id) :: number
		Cart.removeItem(id, item.type)
	end
end

local function onPurchaseFinished(_: Instance, assetId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	Cart.removeItem(assetId, Enum.MarketplaceProductType.AvatarAsset)
end

local function onBundlePurchaseFinished(_: Instance, bundleId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	Cart.removeItem(bundleId, Enum.MarketplaceProductType.AvatarBundle)
end

function Cart.getItem(itemId: number, itemType: Enum.MarketplaceProductType): ItemContainer.ContainedItem?
	return container:getItem(itemId, itemType)
end

function Cart.addItemAsync(itemId: number, itemType: Enum.MarketplaceProductType)
	local items = container:getItems()

	-- Don't allow more than the max items in the cart
	if #items >= MAX_ITEMS then
		return
	end

	-- Get either the asset or bundle details based on itemType
	local itemDetails: Types.BundleDetails | Types.AssetDetails
	if itemType == Enum.MarketplaceProductType.AvatarBundle then
		itemDetails = ItemDetailsCache.getBundleDetailsAsync(itemId) :: Types.BundleDetails
	else
		itemDetails = ItemDetailsCache.getAssetDetailsAsync(itemId) :: Types.AssetDetails
	end

	if not itemDetails then
		warn(`Failed to fetch details for {itemId}-{itemType}`)
		return
	end

	local price = itemDetails.LowestPrice or itemDetails.Price
	if not price then
		warn(`{itemId} has no defined price!`)
		return
	end

	if itemDetails.IsOffSale then
		warn(`{itemDetails.Name} is off sale!`)
		return
	end

	container:addItem(itemId, itemType, { price = price, name = itemDetails.Name })
end

function Cart.removeItem(itemId: number, itemType: Enum.MarketplaceProductType, deleting: boolean?)
	container:removeItem(itemId, itemType, deleting)
end

function Cart.getItems(): { ItemContainer.ContainedItem }
	return container:getItems()
end

-- Calculate the total price of all items in the cart
function Cart.getTotalPrice(): number
	local items = container:getItems()
	local totalPrice = 0

	for _, item in items do
		totalPrice += item.data.price
	end

	return totalPrice
end

function Cart.checkout()
	-- We can't checkout if there aren't any items in the cart
	local items = Cart.getItems()
	if #items == 0 then
		return
	end

	-- We need to convert the list of items to the format expected by MarketplaceService:PromptBulkPurchase()
	local bulkPurchaseItems = {}
	for _, item in items do
		table.insert(bulkPurchaseItems, {
			Id = tostring(item.id),
			Type = item.type,
		})
	end

	-- Since PromptBulkPurchase can't be used on the client, we send the list of items to the server
	bulkPurchaseRemote:FireServer(bulkPurchaseItems)
end

MarketplaceService.PromptPurchaseFinished:Connect(onPurchaseFinished)
MarketplaceService.PromptBundlePurchaseFinished:Connect(onBundlePurchaseFinished)
MarketplaceService.PromptBulkPurchaseFinished:Connect(onBulkPurchaseFinished)

return Cart
