--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folder
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local PlayerGui = localPlayer.PlayerGui
local ClaimedShopGui = PlayerGui:WaitForChild("ClaimedShopGui")
local EditFurnitureFrame = ClaimedShopGui:WaitForChild("EditFurnitureFrame")
local MainHUDGui = PlayerGui:WaitForChild("MainHUD")
local ShopButtons = MainHUDGui:WaitForChild("ShopButtons")
local editShopButton = ShopButtons:WaitForChild("EditShopButton")
local CloseShopButton 		= ShopButtons:WaitForChild("CloseShopButton")

-- Module Scripts
local ShopGuiFSM = require(UtilityFolder:WaitForChild("ShopGuiFSM"))

-- Remotes / Bindables
local playerClosedShopBindable = BindablesFolder:WaitForChild("PlayerClosedShopBindable")
local playerExitedShopAsync = RemotesFolder:WaitForChild("PlayerExitedShop")
local PlayerClaimedShopAsync = RemotesFolder:WaitForChild("PlayerClaimedShop")
local CloseShopButtonClickedAsync = RemotesFolder:WaitForChild("CloseShopButtonClicked")

-- Variables
local inEditGui: boolean = false

--

-- TODO: This ALL has to be made more sensible, it is utterly incoherent right now
-- TODO: MERGE THIS INTO MAINHUD SCRIPT

local function onEditButtonClicked()
	if ShopGuiFSM.CurrentState ~= "EditingBase" then
		print("Into edit mode")
		ShopGuiFSM.setState("EditingBase")
	else
		print("Out of edit mode")
		ShopGuiFSM.setState("None")
	end
end

local function onOwnShopExited()
	ShopGuiFSM.setState("None")
end

local function closeClaimedShopGui()
	editShopButton.Visible = false
end

local function onShopClaimed()
	CloseShopButton.Visible = true
end

local function onCloseShopButtonClicked()
	closeClaimedShopGui()
	CloseShopButtonClickedAsync:FireServer()
	playerClosedShopBindable:Fire()
	ShopGuiFSM.setState("None")
	CloseShopButton.Visible = false
end

local function enterEditGui(x, y)
	inEditGui = true
end

local function exitEditGui(x, y)
	inEditGui = false
end

playerExitedShopAsync.OnClientEvent:Connect(onOwnShopExited)
PlayerClaimedShopAsync.OnClientEvent:Connect(onShopClaimed)
CloseShopButton.Activated:Connect(onCloseShopButtonClicked) 
editShopButton.Activated:Connect(onEditButtonClicked)

EditFurnitureFrame.MouseEnter:Connect(enterEditGui)
EditFurnitureFrame.MouseLeave:Connect(exitEditGui) 