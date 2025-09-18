--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Libraries 	= ReplicatedStorage:WaitForChild("Libraries")
local DataTables 	= ReplicatedStorage:WaitForChild("DataTables")
local Bindables 	= ReplicatedStorage:WaitForChild("Bindables") 
local Remotes 		= ReplicatedStorage:WaitForChild("Remotes")
local Utility 		= ReplicatedStorage:WaitForChild("Utility")

-- Modules
local BuyableShopItems = require(DataTables:WaitForChild("BuyableShopItems"))
local ModalManager = require(Libraries:WaitForChild("ModalManager"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local ShopGuiFsm  = require(Utility:WaitForChild("ShopGuiFSM"))

-- Remotes / Bindables
local PlayerClickedShopItemThumbnailAsync = Bindables:WaitForChild("PlayerClickedShopItemThumbnail")
local GetPlayerOwnedItems = Remotes:WaitForChild("GetPlayerOwnedItems")
local SetPlayerOwnedItems = Remotes:WaitForChild("SetPlayerOwnedItems")
local PlayerClickedAddToShopAsync = Bindables:WaitForChild("PlayerClickedAddToShop")



-- Instances
local localPlayer = Players.LocalPlayer

-- PlayerGUI
local PlayerGui = localPlayer.PlayerGui
local ClaimedShopGui = PlayerGui:WaitForChild("ClaimedShopGui")
local ShopItemFocusFrame = ClaimedShopGui:WaitForChild("ShopItemFocusFrame")

local ItemFrame 		= ShopItemFocusFrame:WaitForChild("ItemFrame")
local DetailsFrame 		= ItemFrame:WaitForChild("DetailsFrame")
local ThumbnailFrame 	= ItemFrame:WaitForChild("ThumbnailFrame")
local ColourFrame 		= ItemFrame:WaitForChild("ColourFrame")
local NameLabel 		= DetailsFrame:WaitForChild("NameLabel")
local Description 		= DetailsFrame:WaitForChild("Description")
local Thumbnail 		= ThumbnailFrame:WaitForChild("Thumbnail")
local BuyFrame			= ThumbnailFrame:WaitForChild("BuyFrame")
local BuyButton 		= BuyFrame:WaitForChild("BuyButton")
local CostButton		= BuyFrame:WaitForChild("CostButton")
local AddButton 		= ThumbnailFrame:WaitForChild("AddButton")

local TopBar 		= ShopItemFocusFrame:WaitForChild("TopBar")
local CloseButton 	= TopBar:WaitForChild("CloseButton")

local itemDetails

local function reset()
	Thumbnail.Image = ""
	Description.Text = ""
	NameLabel.Text = ""
	CostButton.Text = ""
	print("Just reset")
	
end

local function close()
	ShopGuiFsm.setState("FurnitureStore")
	reset()
end



local function update(itemName : string)
	itemDetails = BuyableShopItems[itemName]
	
	if not itemDetails then
		assert(itemDetails, "No itemdetails in BuyableShopItems for provided string!")
		return
	end
	
	NameLabel.Text = itemDetails.Name
	Description.Text = itemDetails.Description
	
	if itemDetails.ThumbnailId then
		Thumbnail.Image = "rbxassetid://"..itemDetails.ThumbnailId
	end
	
	CostButton.Text = itemDetails.Price
	
	local playerOwnedItems = GetPlayerOwnedItems:InvokeServer(localPlayer.UserId)
	if playerOwnedItems[itemName] == "true" then
		BuyFrame.Visible = false
		AddButton.Visible = true
	else
		BuyFrame.Visible = true
		AddButton.Visible = false
	end
	print("Updated")

end

local function onAddToShopClicked()
	PlayerClickedAddToShopAsync:Fire(NameLabel.Text, itemDetails["ItemType"], Constants.PLACE_COMMAND)
	ShopGuiFsm.setState("None")
	reset()
end

local function onBuyItemClicked()
	if BuyFrame.CostButton.Text == "Free" then
		SetPlayerOwnedItems:InvokeServer(NameLabel.Text, "true")
	end 
	update(NameLabel.Text)
end

local function initialise()
	CloseButton.Activated:Connect(close)
	BuyButton.Activated:Connect(onBuyItemClicked)
	AddButton.Activated:Connect(onAddToShopClicked)

end

initialise()

PlayerClickedShopItemThumbnailAsync.Event:Connect(update)