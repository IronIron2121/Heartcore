--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DatastoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Remotes
local PlayerSavedOutfitWithUnownedAssets = Remotes:WaitForChild("PlayerSavedOutfitWithUnownedAssets")

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



return OutfitServerService
