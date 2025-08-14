
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")

-- Module Scripts
local ItemSelection = require(UtilityFolder:WaitForChild("ItemSelection"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local ShopGuiFSM = require(UtilityFolder:WaitForChild("ShopGuiFSM"))

-- Remotes / Bindables
local PlayerClickedAddToShop = BindablesFolder:WaitForChild("PlayerClickedAddToShop")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local PlayerGui = localPlayer.PlayerGui
local ClaimedShopGui = PlayerGui:WaitForChild("ClaimedShopGui")
local EditFurnitureFrame = ClaimedShopGui:WaitForChild("EditFurnitureFrame")
local DeleteButton = EditFurnitureFrame:WaitForChild("DeleteButton")
local RepositionButton = EditFurnitureFrame:WaitForChild("RepositionButton")
local RecolourButton = EditFurnitureFrame:WaitForChild("RecolourButton")
local DuplicateButton = EditFurnitureFrame:WaitForChild("DuplicateButton")


local function onDuplicateButtonActivated()
	print(ItemSelection.selectedItem.Name, ItemSelection.selectedItem:GetAttribute(Constants.ITEM_TYPE_ATTRIBUTE), Constants.PLACE_COMMAND)

	PlayerClickedAddToShop:Fire(ItemSelection.selectedItem.Name, ItemSelection.selectedItem:GetAttribute(Constants.ITEM_TYPE_ATTRIBUTE), Constants.PLACE_COMMAND)
	ItemSelection.unSelectItem()
end

local function onDeleteButtonActivated()
	ItemSelection.deleteSelectedItem()
	ItemSelection.unSelectItem()
end

local function onRepositionButtonActivated()
	ShopGuiFSM.setState("RepositioningMannequin")
end

local function onRecolourButtonActivated()
	ShopGuiFSM.setState("ColouringFurniture")
end

RepositionButton.Activated:Connect(onRepositionButtonActivated)
DuplicateButton.Activated:Connect(onDuplicateButtonActivated)
RecolourButton.Activated:Connect(onRecolourButtonActivated)
DeleteButton.Activated:Connect(onDeleteButtonActivated)