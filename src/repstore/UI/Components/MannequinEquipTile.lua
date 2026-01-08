--!strict

--[[
	MannequinEquipTile - This function acts as a basic UI component, implementing an item 'tile'. The tile
	displays the item name, icon, and price, and allows the user to equip any accessory to a mannequin instantly.
--]]

--[[

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local LibrariesFolder = ReplicatedStorage:WaitForChild("Libraries")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local RemotesFolder	= ReplicatedStorage:WaitForChild("Remotes")
local UIFolder = ReplicatedStorage:WaitForChild("UI")
local ComponentsFolder = UIFolder:WaitForChild("Components")
local ObjectsFolder = UIFolder:WaitForChild("Objects")

-- Module Scripts
local ItemContainer = require(UtilityFolder:WaitForChild("ItemContainer"))
local EquipButton = require(ComponentsFolder:WaitForChild("EquipButton"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(UtilityFolder:WaitForChild("Types"))

-- Components
local limitedULabelTemplate = ObjectsFolder:WaitForChild("LimitedULabel")
local limitedLabelTemplate = ObjectsFolder:WaitForChild("LimitedLabel")
local mannequinEquipTileTemplate = ObjectsFolder:WaitForChild("MannequinEquipTileTemplate")

-- Creates an 'MannequinEquipTile' from an AssetDetails / BundleDetails object, which contain all relevant details for a given asset or bundle
local function MannequinEquipTile(itemDetails: Types.AssetDetails | Types.BundleDetails, mannequinId: number?): Frame?
	local productType = Enum.MarketplaceProductType[`Avatar{itemDetails.ItemType}`]
	local price = itemDetails.LowestPrice or itemDetails.Price

	local mannequinEquipTile = mannequinEquipTileTemplate:Clone()
	mannequinEquipTile.NameLabel.Text = itemDetails.Name
	mannequinEquipTile.PriceLabel.Text = itemDetails.PriceStatus or `{Constants.ROBUX_CHAR}{price}`
	
	local itemButton = EquipButton(itemDetails.Id, productType)
	if not itemButton then 
		warn("No item button recieved!")
		return nil
	end
	
	itemButton.Parent = mannequinEquipTile

	-- The ItemRestrictions table in itemDetails contains information about various restrictions
	-- on the item, such as whether it is limited or a collectible.
	-- If the item is limited, then we attach the limited label to it
	if table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.LIMITED) then
		local limitedLabel = limitedLabelTemplate:Clone() :: GuiObject
		limitedLabel.Parent = itemButton
	elseif
		table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.LIMITED_U)
		or table.find(itemDetails.ItemRestrictions, Constants.ITEM_RESTRICTIONS.COLLECTIBLE)
	then
		local limitedULabel = limitedULabelTemplate:Clone() :: GuiObject
		limitedULabel.Parent = itemButton
	end

	return mannequinEquipTile
end

return MannequinEquipTile
]]