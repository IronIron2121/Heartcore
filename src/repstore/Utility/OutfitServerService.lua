--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DatastoreService = game:GetService("DataStoreService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Datastores
local PlayerOutfitsDatastore = DatastoreService:GetDataStore(Constants.PLAYER_OUTFITS_DATASTORE)

local OutfitServerService = {}

function OutfitServerService.SaveCurrentOutfitWithUnownedItems(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidDescription = humanoid:GetAppliedDescription()
	
	local serialisedHumanoidDescription = SerialisationService.SerialiseHumanoidDescription(humanoidDescription)
	
	local success, result = pcall(function()
		PlayerOutfitsDatastore:UpdateAsync(player.UserId, function(oldData)
			local newData = oldData or {}
			table.insert(newData, serialisedHumanoidDescription)
			return newData
		end)
	end)
	if not success then
		print("Failed to saved")
	else
		print("Saved")
	end
	warn(PlayerOutfitsDatastore:GetAsync(player.UserId))
end

function OutfitServerService.GetPlayerTastemakerOutfits(player: Player)
	local success, result = pcall(function()
		local playerOutfits = PlayerOutfitsDatastore:GetAsync(player.UserId)
		warn("Getting t maker outfits @ server")
		print(playerOutfits)
		return playerOutfits
	end)
	
	if not success then
		return {}
	end
	
	return result
end

function OutfitServerService.DeleteOutfit(outfitId: number)
	AvatarEditorService:PromptDeleteOutfit(outfitId)
	AvatarEditorService.PromptDeleteOutfitCompleted:Wait() 
end

function OutfitServerService.playerDeletedTastemakerOutfit(player: Player, index: number)
	local success, result = pcall(function()
		PlayerOutfitsDatastore:UpdateAsync(player.UserId, function(oldData)
			local newData = oldData or {}
			newData[index] = nil
			return newData
		end)
	end)

	return success
end

return OutfitServerService