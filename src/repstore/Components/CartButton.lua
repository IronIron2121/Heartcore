--!strict

--[[
	CartButton - This function acts as a simple UI component, implementing the shop dropdown button.
	When clicked, it toggles the display of the shop UI by either creating or destroying a ShopDisplay component.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cart = require(ReplicatedStorage.Libraries.Cart)
local CartDisplay = require(ReplicatedStorage.UI.Components.CartDisplay)

local player = Players.LocalPlayer :: Player
local playerGui = player.PlayerGui
local cartDisplay: ScreenGui?

local cartButtonTemplate = ReplicatedStorage.UI.Objects.CartButton

local function CartButton(): GuiButton
	local cartButton = cartButtonTemplate:Clone()

	local function updateCount()
		local count = #Cart.getItems()
		cartButton.CountLabel.Text = tostring(count)
	end

	local function onActivated()
		if cartDisplay and cartDisplay.Parent then
			cartDisplay:Destroy()
			cartDisplay = nil 
		else
			local newCartDisplay = CartDisplay(cartButton)
			newCartDisplay.Parent = playerGui
			cartDisplay = newCartDisplay
		end
	end

	cartButton.Activated:Connect(onActivated)
	-- Since these connections are being made on objects outside of cartButton, they won't be disconnected
	-- when cartButton is destroyed. To make sure we aren't leaking connections, we save and disconnect them
	-- manually when cartButton is destroyed.
	local itemAddedConnection = Cart.itemAdded:Connect(updateCount)
	local itemRemovedConnection = Cart.itemRemoved:Connect(updateCount)

	cartButton.Destroying:Once(function()
		itemAddedConnection:Disconnect()
		itemRemovedConnection:Disconnect()
	end)

	updateCount()

	return cartButton
end

return CartButton
