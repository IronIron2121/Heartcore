-- Services
local DataStoreService 		= game:GetService("DataStoreService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")

-- Folders
local RemotesFolder 		= ReplicatedStorage:WaitForChild("Remotes")

-- Module Scripts
local Constants 			= require(ReplicatedStorage:WaitForChild("Constants"))

-- Remotes
local GetPlayerOwnedItems	= RemotesFolder:WaitForChild("GetPlayerOwnedItems")

local OwnedItemsStore		= DataStoreService:GetDataStore(Constants.OWNEDITEMS_DATASTORE)
local SetPlayerOwnedItems 	= RemotesFolder:WaitForChild("SetPlayerOwnedItems")

--TODO: Maybe this should be a module script?

local function getPlayerOwnedItems(player: Player)
	local playerOwnedItems
	local success, err = pcall(function()
		playerOwnedItems = OwnedItemsStore:GetAsync(player.UserId)
		return playerOwnedItems
	end)
	if not success then
		warn("Failed to get player store")
		return
	end
	return playerOwnedItems
end

local function setPlayerOwnedItems(player: Player, item: string, setValue: string)
	print("player item value", player, item, setValue)
	local success, err = pcall(function()
		OwnedItemsStore:UpdateAsync(tostring(player.UserId), function(oldData)
			local ownedData = oldData or {}
			ownedData[item] = "true"
			return ownedData
			
		end)
	end)
	if not success then
		warn("Failed to set player store")
		return
	end
	

end


GetPlayerOwnedItems.OnServerInvoke = getPlayerOwnedItems
SetPlayerOwnedItems.OnServerInvoke = setPlayerOwnedItems