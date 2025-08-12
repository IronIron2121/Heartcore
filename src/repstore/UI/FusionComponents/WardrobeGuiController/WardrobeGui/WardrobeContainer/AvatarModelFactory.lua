--!strict

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Localplayer
local localPlayer = Players.LocalPlayer

-- Modules
local Utils = require(Utility:WaitForChild("Utils"))

-- Cache
local cache = {
	humanoidDescription = nil :: HumanoidDescription?,
	playerModel = nil,
	fallbackPlayerId = 1 -- Builderman!
}

local AvatarModelFactory = {} 

function AvatarModelFactory.GetPlayerHumanoidDescription(userId: number): HumanoidDescription?
	local humanoidDescription = Utils.callWithRetry(function()
		-- change back to local player id
		return Players:GetHumanoidDescriptionFromUserId(userId) :: HumanoidDescription
	end, 5)

	return humanoidDescription
end

function AvatarModelFactory.GetLocalPlayerModel(): Model
	if not cache.humanoidDescription then
		cache.humanoidDescription = AvatarModelFactory.GetPlayerHumanoidDescription(localPlayer.UserId) :: HumanoidDescription
	end
	

	local humanoidModel = Players:CreateHumanoidModelFromDescription(cache.humanoidDescription, Enum.HumanoidRigType.R15)
	local humanoid = humanoidModel:FindFirstChild("Humanoid") :: Humanoid
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	humanoidModel.Name = "PlayerModel"

	return humanoidModel
end

function AvatarModelFactory.CloneLocalPlayerCharacterModel() : Model?
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

	-- Clone the player's character
	character.Archivable = true
	local modelClone = character:Clone()
	character.Archivable = false

	-- Remove scripts and unnecessary parts
	for _, child in pairs(modelClone:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			child:Destroy()
		end
	end
	
	return modelClone
end

function AvatarModelFactory.GetFallbackModel(): Model
	warn("Failed to get player model, getting fallback model!")
	local fallbackDesc = Utils.callWithRetry(function()
		return Players:GetHumanoidDescriptionFromUserId(cache.fallbackPlayerId)
	end, 3)

	warn("Failed to get fallback desc, getting blank description")
	if not fallbackDesc then
		fallbackDesc = Instance.new("HumanoidDescription")
	end

	local fallbackModel = Players:CreateHumanoidModelFromDescription(fallbackDesc, Enum.HumanoidRigType.R15)
	fallbackModel.Name = "PlayerModel"
	
	return fallbackModel
end

return AvatarModelFactory