-- Services
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local RemotesFolder	= ReplicatedStorage:WaitForChild("Remotes")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local LibrariesFolder = ReplicatedStorage:WaitForChild("Libraries")
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")

-- Module Scripts
local ItemSelection = require(UtilityFolder:WaitForChild("ItemSelection"))
local ModalManager = require(LibrariesFolder:WaitForChild("ModalManager"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local ShopGuiFSM = require(UtilityFolder:WaitForChild("ShopGuiFSM"))

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local playerGui = localPlayer.PlayerGui
	-- RepositionGui
local ClaimedShopGui = playerGui:WaitForChild("ClaimedShopGui")
local EditFurnitureFrame = ClaimedShopGui:WaitForChild("EditFurnitureFrame")
local RepositionFrame = ClaimedShopGui:WaitForChild("RepositionFrame")
	-- Sections
local TopBar = RepositionFrame:WaitForChild("TopBar")
local CloseButton = TopBar:WaitForChild("CloseButton")
local Section1 = RepositionFrame:WaitForChild("Section1")
local MoveUpButton = Section1:WaitForChild("MoveUpButton")
local Minus45 = Section1:WaitForChild("Minus45")
local Plus45 = Section1:WaitForChild("Plus45")
local Section2 = RepositionFrame:WaitForChild("Section2")
local RepositionButton = Section2:WaitForChild("RepositionButton")
local MoveRightButton = Section2:WaitForChild("MoveRightButton")
local MoveLeftButton = Section2:WaitForChild("MoveLeftButton")
local Section3 = RepositionFrame:WaitForChild("Section3")
local MoveDownButton = Section3:WaitForChild("MoveDownButton")

-- Remotes | Bindables
local NudgeShopItemAsync = RemotesFolder:WaitForChild("NudgeShopItem")
local RepositionShopItemBindable = BindablesFolder:WaitForChild("RepositionShopItemBindable")


local function leftButtonPressed()
	NudgeShopItemAsync:FireServer(ItemSelection.getSelectedItemId(), "LEFT")
end

local function rightButtonPressed()
	NudgeShopItemAsync:FireServer(ItemSelection.getSelectedItemId(), "RIGHT")
end

local function downButtonPressed()
	NudgeShopItemAsync:FireServer(ItemSelection.getSelectedItemId(), "DOWN")
end

local function upButtonPressed()
	NudgeShopItemAsync:FireServer(ItemSelection.getSelectedItemId(), "UP")
end

local function plusButtonPressed()
	NudgeShopItemAsync:FireServer(ItemSelection.getSelectedItemId(), "PLUS45")
end

local function minusButtonPressed()
	NudgeShopItemAsync:FireServer(ItemSelection.getSelectedItemId(), "MINUS45")
end

-- TODO: Change createPreview chain of logic...if we have different bindables, we can cut out some of the fat here
local function repositionButtonPressed()
	--ModalManager.pop(RepositionFrame)
	--ModalManager.pop(EditFurnitureFrame)
	print("REPOSITION BUTTON CLICKED ~~~~~~~~~~~x")
	RepositionShopItemBindable:Fire(ItemSelection.getSelectedItemName(), ItemSelection.getSelectedItemType(), Constants.REPOSITION_COMMAND)
	ShopGuiFSM.setState("PlacingShopItem")
end

local function closeButtonPressed()
	ShopGuiFSM.setState("HighlightedMannequin")
end

local function initialiseButtons()
	-- Connect movement buttons to activated
	MoveLeftButton.Activated:Connect(leftButtonPressed)
	MoveRightButton.Activated:Connect(rightButtonPressed)
	Minus45.Activated:Connect(minusButtonPressed)
	Plus45.Activated:Connect(plusButtonPressed)
	MoveUpButton.Activated:Connect(upButtonPressed)
	MoveDownButton.Activated:Connect(downButtonPressed)
	RepositionButton.Activated:Connect(repositionButtonPressed)
	CloseButton.Activated:Connect(closeButtonPressed)
end

initialiseButtons()