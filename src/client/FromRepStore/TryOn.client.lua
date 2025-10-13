--!strict

--[[
	TryOn - This script handles the main Try On UI, creating buttons to represent each of
	the items the player is currently trying on.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TryOn = require(ReplicatedStorage.Libraries.TryOn)
local ItemContainer = require(ReplicatedStorage.Utility.ItemContainer)

local TryOnButton = require(ReplicatedStorage.UI.Components.TryOnButton)

local player = Players.LocalPlayer :: Player
local playerGui = player.PlayerGui
local shoppingGui = playerGui:WaitForChild("ShoppingGui")
local tryOnFrame = shoppingGui:WaitForChild("TryOnFrame")

local tryOnButtons: { [string]: ImageButton } = {}

local function onItemAdded(item: ItemContainer.ContainedItem)
	-- Make sure we're not making a duplicate button somehow
	if tryOnButtons[item.key] then
		return
	end

	local tryOnButton 	= TryOnButton(item.id, item.type)
	tryOnButton.Parent 	= tryOnFrame
	tryOnButtons[item.key] 	= tryOnButton
end

local function onItemRemoved(item: ItemContainer.ContainedItem)
	if tryOnButtons[item.key] then
		tryOnButtons[item.key]:Destroy()
		tryOnButtons[item.key] = nil
	end
end

local function initialise()
	TryOn.itemAdded:Connect(onItemAdded)
	TryOn.itemRemoved:Connect(onItemRemoved)

	for _, item in TryOn.getItems() do
		onItemAdded(item)
	end
end

initialise()
