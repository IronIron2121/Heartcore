--!strict

--[[
	ItemTile - This function acts as a basic UI component, implementing an item 'tile'. The tile
	displays the item name, icon, and price, as well as buttons to try on or add the item to the cart.

	This is used both for the shop as well as the mannequin inspect UI.
--]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetManager 		= game:GetService("AssetService")

-- Folders
local DataTablesFolder	= ReplicatedStorage:WaitForChild("DataTables")
local ThumbnailsFolder	= ReplicatedStorage:WaitForChild("Thumbnails")
local Constants			= ReplicatedStorage:WaitForChild("Constants")
local LibrariesFolder	= ReplicatedStorage:WaitForChild("Libraries")
local UtilityFolder 	= ReplicatedStorage:WaitForChild("Utility")
local GettersFolder		= ReplicatedStorage:WaitForChild("Getters")
local RemotesFolder		= ReplicatedStorage:WaitForChild("Remotes")
local UiFolder			= ReplicatedStorage:WaitForChild("UI")
local TypesFolder		= UtilityFolder:WaitForChild("Types")
local ComponentsFolder	= UiFolder:WaitForChild("Components")
local ObjectsFolder		= UiFolder:WaitForChild("Objects")
local BindablesFolder	= ReplicatedStorage:WaitForChild("Bindables")


-- Module Scripts
local arrayOfStringsToString 	= require(UtilityFolder:WaitForChild("arrayOfStringsToString"))
local Types 					= require(UtilityFolder:WaitForChild("Types"))
local getThumbnailFromId		= require(GettersFolder:WaitForChild("getThumbnailFromId"))
local BuyableShopItems 			= require(DataTablesFolder:WaitForChild("BuyableShopItems"))
local Constants 				= require(ReplicatedStorage:WaitForChild("Constants"))
local ModalManager 				= require(LibrariesFolder:WaitForChild("ModalManager"))

-- UI Components
local colourTileTemplate 	= ObjectsFolder:WaitForChild("ColourTile")

-- Remotes | Bindables
local GetPlayerOwnedItems = RemotesFolder:WaitForChild("GetPlayerOwnedItems")
local SetPlayerOwnedItems = RemotesFolder:WaitForChild("SetPlayerOwnedItems")
local PlayerClickedAddToShop = BindablesFolder:WaitForChild("PlayerClickedAddToShop")
--[[
local function ColourTile(player: Player, colour: string): Frame
	-- Create a new tile for this item and initialise all features
	local colourTile = colourTileTemplate:Clone()
	colourTile.NameLabel.Text = 
	local thumbnailUri = getThumbnailFromId(itemDict["ThumbnailId"])
	colourTile.Thumbnail.Image = thumbnailUri


	local PlayerGui	= player.PlayerGui
	local ClaimedShopGui = PlayerGui:WaitForChild("ClaimedShopGui")
	local ShopItemStoreFrame	= ClaimedShopGui:WaitForChild("ShopItemStoreFrame")



	local function onThumbnailClicked()

	end



	colourTile.Thumbnail.Activated:Connect(onThumbnailClicked)

	return colourTile
end
]]
return ColourTile