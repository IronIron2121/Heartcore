--!strict

--[[
	ItemTile - This function acts as a basic UI component, implementing an item 'tile'. The tile
	displays the item name, icon, and price, as well as buttons to try on or add the item to the cart.

	This is used both for the shop as well as the mannequin inspect UI.
--]]
--[[

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players 			= game:GetService("Players")


-- s
local DataTables	= ReplicatedStorage:WaitForChild("DataTables")
local Thumbnails	= ReplicatedStorage:WaitForChild("Thumbnails")
local Constants			= ReplicatedStorage:WaitForChild("Constants")
local Libraries	= ReplicatedStorage:WaitForChild("Libraries")
local Utility 	= ReplicatedStorage:WaitForChild("Utility")
local Getters		= ReplicatedStorage:WaitForChild("Getters")
local Remotes		= ReplicatedStorage:WaitForChild("Remotes")
local Ui			= ReplicatedStorage:WaitForChild("UI")
local Objects		= Ui:WaitForChild("Objects")
local Bindables	= ReplicatedStorage:WaitForChild("Bindables")


-- Instances
local localPlayer = Players.LocalPlayer

-- Module Scripts
local arrayOfStringsToString 	= require(Utility:WaitForChild("arrayOfStringsToString"))
local getThumbnailFromId		= require(Getters:WaitForChild("getThumbnailFromId"))
local Constants 				= require(ReplicatedStorage:WaitForChild("Constants"))
local ShopGuiFsm				= require(Utility:WaitForChild("ShopGuiFSM"))

-- UI Components
local addTileTemplate 	= Objects:WaitForChild("AddTile")


-- PlayerGUI
local PlayerGui				= localPlayer.PlayerGui
local ClaimedShopGui 		= PlayerGui:WaitForChild("ClaimedShopGui")
local ShopItemStoreFrame 	= ClaimedShopGui:WaitForChild("ShopItemStoreFrame")
local ShopItemFocusFrame 	= ClaimedShopGui:WaitForChild("ShopItemFocusFrame")



-- Remotes | Bindables
local PlayerClickedShopItemThumbnailAsync = Bindables:WaitForChild("PlayerClickedShopItemThumbnail")
local PlayerClickedAddToShopAsync = Bindables:WaitForChild("PlayerClickedAddToShop")
local GetPlayerOwnedItems = Remotes:WaitForChild("GetPlayerOwnedItems")
local SetPlayerOwnedItems = Remotes:WaitForChild("SetPlayerOwnedItems")
]]
--[[
local function AddTile(itemDetails: {}): Frame
	warn("Beginning add tile")
	-- Create a new tile for this item and initialise all features
	local addTile = addTileTemplate:Clone()
	local thumbnailUri = getThumbnailFromId(itemDetails["ThumbnailId"])
	addTile.Thumbnail.Image = thumbnailUri
	addTile.NameLabel.Text = itemDetails["Name"]
	addTile.BuyFrame.CostButton.Text = itemDetails["Price"]
	

	
	local itemTags = itemDetails["Tags"]
	addTile:SetAttribute("Tags", arrayOfStringsToString(itemTags))
	-- Function
	local function update()
--		local playerOwnedItems = GetPlayerOwnedItems:InvokeServer(localPlayer.UserId)
]]

--		if playerOwnedItems[itemDetails["Name"]] == "true" then
--[[
			addTile.BuyFrame.Visible = false
			addTile.AddButton.Visible = true
		else
			addTile.BuyFrame.Visible = true
			addTile.AddButton.Visible = false
		end
	end
	
	local function onBuyItemClicked()
		if addTile.BuyFrame.CostButton.Text == "Free" then
			SetPlayerOwnedItems:InvokeServer(addTile.NameLabel.Text, "true")
		end 
		update()
	end
	
	local function onThumbnailClicked()
		PlayerClickedShopItemThumbnailAsync:Fire(addTile.NameLabel.Text)
		ShopGuiFsm.setState("ShopItemFocus")
		
	end
	
	local function onAddToShopClicked()
		ShopGuiFsm.setState("None")
		PlayerClickedAddToShopAsync:Fire(addTile.NameLabel.Text, itemDetails["ItemType"], Constants.PLACE_COMMAND)
	end
	
	addTile.BuyFrame.BuyButton.Activated:Connect(onBuyItemClicked)
	addTile.BuyFrame.CostButton.Activated:Connect(onBuyItemClicked)
	addTile.Thumbnail.Activated:Connect(onThumbnailClicked)
	addTile.AddButton.Activated:Connect(onAddToShopClicked)

	update()

	return addTile
end

return AddTile
]]

return {}