--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Getters = ReplicatedStorage:WaitForChild("Getters")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local GetAccessoryTypeFromAssetTypeId = require(Getters:WaitForChild("GetAccessoryTypeFromAssetTypeId"))

local AvatarPreviewModel = {}
AvatarPreviewModel.__index = AvatarPreviewModel

-- Simple helper to fix AccessoryTypes
local function fixAccessoryTypes(humanoidDescription: HumanoidDescription)
	warn("Attempting to fix accessory type!")
	for _, description in ipairs(humanoidDescription:GetChildren()) do
		if description:IsA("AccessoryDescription") and description.AccessoryType == Enum.AccessoryType.Unknown then
			local success, productInfo = pcall(function()
				return MarketplaceService:GetProductInfo(description.AssetId, Enum.InfoType.Asset)
			end)

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
	fixAccessoryTypes(child)

	-- Update the reactive value
	self.currentHumanoidDescription:set(child)
end

function AvatarPreviewModel:getInstance()
	return self.instance
end

function AvatarPreviewModel:getDescription()
	return self.currentHumanoidDescription
end

return AvatarPreviewModel