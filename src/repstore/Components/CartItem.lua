--!strict

--[[
	CartItem - This function acts as a basic UI component, creating a UI frame for items that are currently
	in the player's cart. The frame is populated with the item's icon, name, and price.

	Functionality is also included to try on the item or remove it from the cart.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Constants)
local Cart = require(ReplicatedStorage.Libraries.Cart)
local ItemContainer = require(ReplicatedStorage.Utility.ItemContainer)

local ItemButton = require(ReplicatedStorage.UI.Components.ItemButton)

local cartItemFrameTemplate = ReplicatedStorage.UI.Objects.CartItemFrame

local function CartItem(cartItem: ItemContainer.ContainedItem): Frame
	local cartItemFrame = cartItemFrameTemplate:Clone()
	cartItemFrame.InfoFrame.NameLabel.Text = cartItem.data.name
	cartItemFrame.InfoFrame.PriceLabel.Text = `{Constants.ROBUX_CHAR}{cartItem.data.price}`

	local itemButton = ItemButton(cartItem.id, cartItem.type)
	itemButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	itemButton.Parent = cartItemFrame

	cartItemFrame.RemoveButton.Activated:Connect(function()
		Cart.removeItem(cartItem.id, cartItem.type)
	end)

	return cartItemFrame
end

return CartItem
