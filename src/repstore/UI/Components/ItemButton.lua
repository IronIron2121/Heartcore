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
local AvatarCustomisationService = require(Utility:WaitForChild("AvatarCustomisationService"))
-- Module Scripts
local ItemContainer 	= require(ReplicatedStorage.Utility.ItemContainer)
local getItemIcon 		= require(ReplicatedStorage.Utility.getItemIcon)
local TryOn 			= require(ReplicatedStorage.Libraries.TryOn)

local itemButtonTemplate = ReplicatedStorage.UI.Objects.ItemButton

local function ItemButton(itemId: number, itemType: Enum.MarketplaceProductType): ImageButton
	local icon = getItemIcon(itemId, itemType)
	
	local itemButton = itemButtonTemplate:Clone()
	itemButton.Image = icon
	itemButton.TryOnFrame.Visible = AvatarCustomisationService.IsWearingItem(LocalPlayer, itemId)

	local function onActivated()
		if AvatarCustomisationService.IsWearingItem(LocalPlayer, itemId) then
			PlayerRemovedItem:FireServer(itemId)
		else
			AvatarCustomisationService.AddItemToAvatar(LocalPlayer, itemId)
		end
	end

	local function onItemAdded(tryOnItem: ItemContainer.ContainedItem)
		if tryOnItem.id == itemId and tryOnItem.type == itemType then
			itemButton.TryOnFrame.Visible = true
		end
	end

	local function onItemRemoved(tryOnItem: ItemContainer.ContainedItem)
		if tryOnItem.id == itemId and tryOnItem.type == itemType then
			itemButton.TryOnFrame.Visible = false
		end
	end

	itemButton.Activated:Connect(onActivated)
	local itemAddedConnection 	= TryOn.itemAdded:Connect(onItemAdded)
	local itemRemovedConnection = TryOn.itemRemoved:Connect(onItemRemoved)

	itemButton.Destroying:Once(function()
		itemAddedConnection:Disconnect()
		itemRemovedConnection:Disconnect()
	end)

	return itemButton
end

return ItemButton
