--!strict

--[[
	ItemTile - This function acts as a basic UI component, implementing an item 'tile'. The tile
	displays the item name, icon, and price, as well as buttons to try on or add the item to the cart.

	This is used both for the shop as well as the mannequin inspect UI.
--]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local LibrariesFolder = ReplicatedStorage:WaitForChild("Libraries")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local RemotesFolder	= ReplicatedStorage:WaitForChild("Remotes")
local UIFolder = ReplicatedStorage:WaitForChild("UI")
local ComponentsFolder = UIFolder:WaitForChild("Components")
local ObjectsFolder = UIFolder:WaitForChild("Objects")

-- Module Scripts
local ItemContainer = require(UtilityFolder:WaitForChild("ItemContainer"))
local ItemButton = require(ComponentsFolder:WaitForChild("ItemButton"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(UtilityFolder:WaitForChild("Types"))
local Cart = require(LibrariesFolder:WaitForChild("Cart"))

-- Components
local limitedULabelTemplate = ObjectsFolder:WaitForChild("LimitedULabel")
local limitedLabelTemplate = ObjectsFolder:WaitForChild("LimitedLabel")
local itemTileTemplate = ObjectsFolder:WaitForChild("ItemTileFrame")
local purchaseRemote = RemotesFolder:WaitForChild("Purchase")


-- Creates an 'ItemTile' from an AssetDetails / BundleDetails object, which contain all relevant details for a given asset or bundle
local function ItemTile(itemDetails: Types.AssetDetails | Types.BundleDetails, mannequinId: number?): Frame

	local productType = Enum.MarketplaceProductType[`Avatar{itemDetails.ItemType}`]
	local price = itemDetails.LowestPrice or itemDetails.Price

	local itemTile = itemTileTemplate:Clone()
	itemTile.NameLabel.Text = itemDetails.Name
	itemTile.PriceLabel.Text = itemDetails.PriceStatus or `{Constants.ROBUX_CHAR}{price}`
	
	local itemButton = ItemButton(itemDetails.Id, productType)
	itemButton.Parent = itemTile

	local addToCartButton = itemTile.ButtonsFrame.AddToCartButton
	local buyButton = itemTile.ButtonsFrame.BuyButton
	local isInCart = Cart.getItem(itemDetails.Id, productType) ~= nil
	local DeleteButton = itemTile.DeleteButton

	addToCartButton.IconLabel.ImageTransparency = if isInCart then Constants.BUTTON_DISABLED_TRANSPARENCY else 0

	-- The ItemRestrictions table in itemDetails contains information about various restrictions
	-- on the item, such as whether it is limited or a collectible.
	-- If the item is limited, then we attach the limited label to it
	if table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.LIMITED) then
		local limitedLabel = limitedLabelTemplate:Clone() :: GuiObject
		limitedLabel.Parent = itemButton
	elseif
		table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.LIMITED_U)
		or table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.COLLECTIBLE)
	then
		local limitedULabel = limitedULabelTemplate:Clone() :: GuiObject
		limitedULabel.Parent = itemButton
	end

	local function onBuyButtonActivated()
		purchaseRemote:FireServer(itemDetails.Id, productType)
	end

	local function onAddToCartButtonActivated()
		Cart.addItemAsync(itemDetails.Id, productType)
	end
	
	local function onDeleteButtonActivated()
		ReplicatedStorage.Remotes.DeleteAccessory:InvokeServer(itemDetails.Id, mannequinId)
		
		local item = Cart.getItem(itemDetails.Id, productType)
		if item then
			Cart.removeItem(itemDetails.Id, productType, true)
		end
		
		itemTile:Destroy()
	end

	-- Triggers when an item is added to the cart
	local function onItemAdded(cartItem: ItemContainer.ContainedItem)
		if cartItem.id == itemDetails.Id and cartItem.type == productType then
			addToCartButton.IconLabel.ImageTransparency = Constants.BUTTON_DISABLED_TRANSPARENCY
		end
	end
	
	-- Triggers when an item is removed from the cart
	local function onItemRemoved(cartItem: ItemContainer.ContainedItem, deleting: boolean)
		if cartItem.id == itemDetails.Id and cartItem.type == productType and not deleting then
			addToCartButton.IconLabel.ImageTransparency = 0
		end
	end
	
	buyButton.Activated:Connect(onBuyButtonActivated)
	addToCartButton.Activated:Connect(onAddToCartButtonActivated)
	DeleteButton.Activated:Connect(onDeleteButtonActivated)
	
	-- Since these connections are being made on objects outside of itemTile, they won't be disconnected
	-- when itemTile is destroyed. To make sure we aren't leaking connections, we save and disconnect them
	-- manually when itemTile is destroyed.
	local itemAddedConnection = Cart.itemAdded:Connect(onItemAdded)
	local itemRemovedConnection = Cart.itemRemoved:Connect(onItemRemoved)

	itemTile.Destroying:Once(function()
		itemAddedConnection:Disconnect()
		itemRemovedConnection:Disconnect()
	end)

	return itemTile
end

return ItemTile