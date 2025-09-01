--!strict

--[[
	ItemButton - This function acts as a simple UI component, implementing a UI button that displays
	an item icon. When clicked, it toggles whether the player is trying on the item or not. This is
	used in the main item tile component, as well as in the cart to allow users to easily try on items.
--]]


-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- localplayer
local LocalPlayer = Players.LocalPlayer

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")
local PlayerEquippedItem = Remotes:WaitForChild("PlayerEquippedItem")
local AvatarCustomisationService = require(Utility:WaitForChild("AvatarCustomisationService"))
-- Module Scripts
local ItemContainer 	= require(ReplicatedStorage.Utility.ItemContainer)
local getItemIcon 		= require(ReplicatedStorage.Utility.getItemIcon)
local TryOn 			= require(ReplicatedStorage.Libraries.TryOn)

local itemButtonTemplate = ReplicatedStorage.UI.Objects.ItemButton

local function ItemButton(itemId: number, productType: Enum.MarketplaceProductType, assetType: string, itemType: string): ImageButton

	local icon = getItemIcon(itemId, productType)
	
	local itemButton = itemButtonTemplate:Clone()
	itemButton.Image = icon

	local function refresh()
		itemButton.TryOnFrame.Visible = AvatarCustomisationService.IsWearingItem(LocalPlayer, itemId)
	end

	local function onActivated()
		if AvatarCustomisationService.IsWearingItem(LocalPlayer, itemId) then
			PlayerRemovedItem:FireServer(itemId)
			itemButton.TryOnFrame.Visible = false
		else
			PlayerEquippedItem:FireServer(itemId, assetType, itemType)
			itemButton.TryOnFrame.Visible = true

		end
		print(itemButton.TryOnFrame.Visible)
	end

	itemButton.Activated:Connect(onActivated)

	refresh()
	return itemButton
end

return ItemButton
