-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DataTablesFolder = ReplicatedStorage:WaitForChild("DataTables")

-- Module Scripts
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local BuyableShopItems = require(DataTablesFolder:WaitForChild("BuyableShopItems"))

function getFurnitureTableEntry(furnitureItem: Model): {}?
	local furnitureType = furnitureItem:GetAttribute(Constants.ITEM_TYPE_ATTRIBUTE)
	if not furnitureType then
		warn("No item type for item ", furnitureItem.Name)
		return nil
	end
	local furnitureTable = BuyableShopItems[furnitureType]
	for _, item in pairs(furnitureTable) do
		if item.Name == furnitureItem.Name then
			return item
		end
	end
	warn("Could not find furniture entry for this item")
	return nil
end

return getFurnitureTableEntry
