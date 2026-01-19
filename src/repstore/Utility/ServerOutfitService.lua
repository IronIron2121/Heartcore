--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DatastoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Datastores
local PlayerOutfitsDatastore = DatastoreService:GetDataStore(Constants.PLAYER_OUTFITS_DATASTORE)

local ServerOutfitService = {}

function ServerOutfitService.SaveCurrentOutfitWithUnownedItems(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidDescription = humanoid:GetAppliedDescription()
	
	local serialisedHumanoidDescription = SerialisationService.SerialiseHumanoidDescription(humanoidDescription)
	
	local success = pcall(function()
		PlayerOutfitsDatastore:UpdateAsync(player.UserId, function(oldData)
			local newData = oldData or {}
			table.insert(newData, serialisedHumanoidDescription)
			return newData
		end)
	end)
	if not success then
		warn("Failed to saved")
	end
end

function ServerOutfitService.GetPlayerTastemakerOutfits(player: Player)
	local success, result = pcall(function()
		local playerOutfits = PlayerOutfitsDatastore:GetAsync(player.UserId)
		return playerOutfits
	end)
	
	if not success then
		return {}
	end
	
	return result
end

function ServerOutfitService.DeleteOutfit(outfitId: number)
	AvatarEditorService:PromptDeleteOutfit(outfitId)
	AvatarEditorService.PromptDeleteOutfitCompleted:Wait() 
end

function ServerOutfitService.PlayerPurchasedCurrentOutfit(player: Player, shoppingCart: {Type: Enum.MarketplaceProductType, itemId: number})
	local success = callWithRetry(
		function()
			return MarketplaceService:PromptBulkPurchase(player, shoppingCart, {})
		end,
		3 
	)

	return success
end

function ServerOutfitService.playerDeletedTastemakerOutfit(player: Player, index: number)
	local success = pcall(function()
		PlayerOutfitsDatastore:UpdateAsync(player.UserId, function(oldData)
			local newData = oldData or {}
			newData[index] = nil
			return newData
		end)
	end)

	return success
end

return ServerOutfitService 