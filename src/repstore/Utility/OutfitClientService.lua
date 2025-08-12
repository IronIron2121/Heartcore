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
--local PlayerOutfitsDatastore = DatastoreService:GetDataStore(Constants.PLAYER_OUTFITS_DATASTORE)

local OutfitClientService = {}

function OutfitClientService.SaveCurrentPlayerOutfit(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidDescription = humanoid:GetAppliedDescription()
	
	for _, description in ipairs(humanoidDescription:GetChildren()) do
		if description:IsA("AccessoryDescription") or description:IsA("BodyPartDescription") and description.AssetId ~= 0 then
			if MarketplaceService:PlayerOwnsAsset(player, description.AssetId) then
				continue
			else
				PlayerSavedOutfitWithUnownedAssets:FireServer()
				-- do local outfit creation\
				return
			end
		end
	end
	
	AvatarEditorService:PromptCreateOutfit(humanoidDescription, Enum.HumanoidRigType.R15)
end

function OutfitClientService.DeleteOutfit(outfitId: number)
	AvatarEditorService:PromptDeleteOutfit(outfitId)
	AvatarEditorService.PromptDeleteOutfitCompleted:Wait()
end



return OutfitClientService
