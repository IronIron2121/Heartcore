--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Getters = ReplicatedStorage:WaitForChild("Getters")

-- Modules
local GetAccessoryTypeFromAssetTypeId = require(Getters:WaitForChild("GetAccessoryTypeFromAssetTypeId"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local Fusion = require(Utility:WaitForChild("Fusion"))
local peek = Fusion.peek

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local LoadEmoteRF = Remotes:WaitForChild("LoadEmoteRF")

-- Folders
local Emotes = ReplicatedStorage:WaitForChild("Emotes")

local AvatarPreviewModel = {}
AvatarPreviewModel.__index = AvatarPreviewModel
 
-- Simple helper to fix AccessoryTypes
local function fixAccessoryTypes(humanoidDescription: HumanoidDescription)
	for _, description in ipairs(humanoidDescription:GetChildren()) do
		if description:IsA("AccessoryDescription") and description.AccessoryType == Enum.AccessoryType.Unknown then
			warn("Attempting to fix accessory type!")
			local success, productInfo = callWithRetry(function()
				return MarketplaceService:GetProductInfo(description.AssetId, Enum.InfoType.Asset)
			end, 5)

			if success then
				local accessoryType = GetAccessoryTypeFromAssetTypeId(productInfo.AssetTypeId)
				if accessoryType then
					description.AccessoryType = accessoryType
				else
					warn("Could not determine AccessoryType for asset:", description.AssetId)
					description:Destroy() -- Remove if we can't determine type
				end
			else
				warn("Failed to get product info for asset:", description.AssetId)
				description:Destroy() -- Remove if we can't get info
			end
		end
	end
end

function AvatarPreviewModel.new(scope: Fusion.Scope)
	local self = setmetatable({}, AvatarPreviewModel)

	-- Get local player info
	local localPlayer = Players.LocalPlayer
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")

	-- Store the current HumanoidDescription as a reactive Value
	self.currentHumanoidDescription = scope:Value(humanoid:WaitForChild("HumanoidDescription"))

	-- Create a Computed that automatically updates the model when HumanoidDescription changes
	self.instance = scope:Computed(function(use)
		local description = use(self.currentHumanoidDescription)
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)

	-- Watch for HumanoidDescription changes
	humanoid.ChildAdded:Connect(function(child)
		if child:IsA("HumanoidDescription") then
			self:onHumanoidDescriptionChanged(child)
		end
	end)

	return self
end

function AvatarPreviewModel:onHumanoidDescriptionChanged(child: HumanoidDescription)
	-- Fix any Unknown AccessoryTypes
	--fixAccessoryTypes(child)

	-- Update the reactive value
	self.currentHumanoidDescription:set(child)
end

function AvatarPreviewModel:getInstance()
	return self.instance
end

function AvatarPreviewModel:getDescription()
	return self.currentHumanoidDescription
end

function AvatarPreviewModel:PlayAnimation(animationId: number)
	local model = peek(self.instance)
	if not model then 
		warn("No model at play animation!")
		return  end

	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then 
		warn("No humanoid at play animation!") 
		return 
	end

	local animator: Animator = humanoid:FindFirstChild("Animator") :: Animator
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local success, emoteLoaded = callWithRetry(function()
		return LoadEmoteRF:InvokeServer(animationId)
	end)

	if not success or not emoteLoaded then 
		return 
	end

	local emoteSuccess, animation = callWithRetry(function()
		return Emotes:FindFirstChild(tostring(animationId))
	end)

	if not emoteSuccess or not animation then 
		return
	end

	local track = (animator :: Animator):LoadAnimation(animation)
	track.Looped = false
	track:Play()
end

return AvatarPreviewModel