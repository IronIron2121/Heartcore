--!strict

--[[
	CartDisplay - This function acts as a basic UI component, implementing the cart menu.
	The cart displays which items are in the cart, along with the total price and a purchase
	button to perform a bulk purchase of all items in the cart.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Constants)
local Cart = require(ReplicatedStorage.Libraries.Cart)
local ItemContainer = require(ReplicatedStorage.Utility.ItemContainer)
local safeClamp = require(ReplicatedStorage.Utility.safeClamp)
local connectTreeVisibilityChanged = require(ReplicatedStorage.Utility.connectTreeVisibilityChanged)

local CartItem = require(ReplicatedStorage.UI.Components.CartItem)

local cartDisplayTemplate = ReplicatedStorage.UI.Objects.CartGui

local function CartDisplay(parent: GuiObject): ScreenGui
	local itemFrames: { [string]: Frame } = {}

	local cartDisplay = cartDisplayTemplate:Clone()
	local cartFrame = cartDisplay.CartFrame

	local function updatePosition()
		local xPosition = parent.AbsolutePosition.X
		local yPosition = parent.AbsolutePosition.Y + parent.AbsoluteSize.Y

		-- Clamp X and Y position to keep the cart display within the screen bounds
		xPosition = safeClamp(xPosition, 0, cartDisplay.AbsoluteSize.X - cartFrame.AbsoluteSize.X)
		yPosition = safeClamp(yPosition, 0, cartDisplay.AbsoluteSize.Y - cartFrame.AbsoluteSize.Y)

		cartFrame.Position = UDim2.fromOffset(xPosition, yPosition)
	end

	local function updateCountAndPrice()
		local count = #Cart.getItems()
		local totalPrice = Cart.getTotalPrice()

		cartFrame.TitleLabel.Text = `Cart ({count})`
		cartFrame.TotalLabel.Text = `Total: {Constants.ROBUX_CHAR}{totalPrice}`
	end

	local function onItemAdded(item: ItemContainer.ContainedItem)
		-- Make sure we're not creating duplicates somehow
		if itemFrames[item.key] then
			return
		end

		-- Create a new CartItem component for each item added to the cart
		local cartItem = CartItem(item)
		cartItem.Parent = cartFrame.CartItemsFrame

		itemFrames[item.key] = cartItem

		updateCountAndPrice()
	end

	local function onItemRemoved(item: ItemContainer.ContainedItem)
		if itemFrames[item.key] then
			itemFrames[item.key]:Destroy()
			itemFrames[item.key] = nil
		end

		updateCountAndPrice()
	end

	local function onTreeVisibilityChanged(isVisible: boolean)
		if not isVisible then
			cartDisplay:Destroy()
		end
	end

	cartFrame.BuyButton.Activated:Connect(Cart.checkout)
	cartFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)

	-- Since these connections are being made on objects outside of cartDisplay, they won't be disconnected
	-- when cartDisplay is destroyed. To make sure we aren't leaking connections, we save and disconnect them
	-- manually when cartDisplay is destroyed.
	local positionChangedConnection = parent:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePosition)
	local itemAddedConnection = Cart.itemAdded:Connect(onItemAdded)
	local itemRemovedConnection = Cart.itemRemoved:Connect(onItemRemoved)

	local disconnectTreeVisibilityChanged = connectTreeVisibilityChanged(parent, onTreeVisibilityChanged)

	cartDisplay.Destroying:Once(function()
		positionChangedConnection:Disconnect()
		itemAddedConnection:Disconnect()
		itemRemovedConnection:Disconnect()
		disconnectTreeVisibilityChanged()
	end)

	updatePosition()
	updateCountAndPrice()
	for _, item in Cart.getItems() do
		onItemAdded(item)
	end

	return cartDisplay
end

return CartDisplay
