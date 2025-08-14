-- Services
local DataStoreService 		= game:GetService("DataStoreService")
local ReplicatedStorage 	= game:GetService("ReplicatedStorage")

-- Module Scripts
local Constants 			= ReplicatedStorage:WaitForChild("Constants")
local ownedItemsDataStore	= DataStoreService:GetDataStore(Constants.OWNEDITEMS_DATASTORE)


function doesPlayerOwnItem(userId: number, targetItem: string): boolean
	local playerOwnedItems = ownedItemsDataStore:GetAsync(tostring(userId))
	return playerOwnedItems[targetItem]
	
end

return doesPlayerOwnItem
