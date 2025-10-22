--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

-- Remotes
local PlayerSavedTastemakerOutfit = Remotes:WaitForChild("PlayerSavedTastemakerOutfit")
local PlayerDeletedTastemakerOutfit = Remotes:WaitForChild("PlayerDeletedTastemakerOutfit")

--

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
				PlayerSavedTastemakerOutfit:FireServer()
				-- do local outfit creation
				return
			end
		end
	end

	for _, itemType in Constants.CLASSIC_HUMANOID_CLOTHING_ASSET_TYPES do
		if MarketplaceService:PlayerOwnsAsset(player, humanoidDescription[itemType]) then
			continue
		else
			PlayerSavedTastemakerOutfit:FireServer()
			-- do local outfit creation
			return
		end
	end
	
	AvatarEditorService:PromptCreateOutfit(humanoidDescription, Enum.HumanoidRigType.R15)
end

function OutfitClientService.DeleteOutfit(outfitId: number)
	AvatarEditorService:PromptDeleteOutfit(outfitId)
	AvatarEditorService.PromptDeleteOutfitCompleted:Wait()
end

function OutfitClientService.DeleteTastemakerOutfit(outfitIndex: number)
	return PlayerDeletedTastemakerOutfit:InvokeServer(outfitIndex)
end

return OutfitClientService