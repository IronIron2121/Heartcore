--!strict

--[[
	ItemContainer - A utility module used for holding a de-duplicated list of catalog items, storing
	their details along with them to be used by various systems without making extra calls to the cache.

	This is used by both the Cart and TryOn system, as they both store a list of catalog items and
	access different details from them.
--]]

export type ContainedItem = {
	key: string,
	id: number,
	type: Enum.MarketplaceProductType,
	data: { [string]: any },
}

local ItemContainer = {}
ItemContainer.__index = ItemContainer

function ItemContainer.new()
	local itemAdded = Instance.new("BindableEvent")
	local itemRemoved = Instance.new("BindableEvent")

	local self = {
		_items = {},
		_adding = {},
		_itemAddedBindable = itemAdded,
		_itemRemovedBindable = itemRemoved,
		itemAdded = itemAdded.Event,
		itemRemoved = itemRemoved.Event,
	}
	setmetatable(self, ItemContainer)
	return self
end

function ItemContainer:addItem(itemId: number, itemType: Enum.MarketplaceProductType, data: { [string]: any }?)
	-- Don't allow inserting duplicate items
	if self:getItem(itemId, itemType) then
		return
	end
	local key = `{itemId}-{itemType}`

	local item = {
		id = itemId,
		type = itemType,
		key = key,
		data = data or {},
	}

	table.insert(self._items, item)
	self._itemAddedBindable:Fire(item)
end

-- Safely remove item (do nothing if no index or item)
function ItemContainer:removeItem(itemId: number, itemType: Enum.MarketplaceProductType, deleting: boolean?)
	-- Deleting default value is false
	local deleting = deleting or false
	local item, index = self:getItem(itemId, itemType)
	if item and index then
		table.remove(self._items, index)
		self._itemRemovedBindable:Fire(item, deleting)
	end
end

function ItemContainer:getItem(itemId: number, itemType: Enum.MarketplaceProductType): (ContainedItem?, number?)
	for index, item in self._items do
		if item.id == itemId and item.type == itemType then 	
			return item, index
		end
	end

	return nil, nil
end

function ItemContainer:getItems(): { ContainedItem }
	return table.clone(self._items)
end

function ItemContainer:setItems(items: { { id: number, type: Enum.MarketplaceProductType } })
	for _, item in self._items do
		self._itemRemovedBindable:Fire(item)
	end

	table.clear(self._items)

	for _, itemInfo in items do
		self:addItem(itemInfo.id, itemInfo.type)
	end
end

return ItemContainer
