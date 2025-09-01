--!strict
-- AvatarCustomisationService - Handles adding, removing, and checking avatar items

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Getters = ReplicatedStorage:WaitForChild("Getters")
local Checkers = ReplicatedStorage:WaitForChild("Checkers")

-- Modules
local GetHumanoidFromPlayer = require(Getters:WaitForChild("GetHumanoidFromPlayer"))
local GetAccessoryTypeFromAssetType = require(Getters:WaitForChild("GetAccessoryTypeFromAssetType"))
local PlayerHasMaxOfAccessoryTypeEquipped = require(Checkers:WaitForChild("PlayerHasMaxOfAccessoryTypeEquipped"))

-- Constants
local DEFAULT_BODY_COLOR = Color3.fromRGB(200, 200, 200)

local AvatarCustomisationService = {}

-- Private helper functions
local function getClonedDescription(player: Player): HumanoidDescription
	local humanoid = GetHumanoidFromPlayer(player)
	local humanoidDescription = humanoid:WaitForChild("HumanoidDescription") :: HumanoidDescription
	return humanoidDescription:Clone()
end

local function findItemDescription(description: HumanoidDescription, itemId: number)
	for _, child in pairs(description:GetChildren()) do
		if child.AssetId == itemId then
			return child
		end
	end

	return nil
end

function AvatarCustomisationService.applyDescription(player: Player, description: HumanoidDescription)
	local humanoid = GetHumanoidFromPlayer(player)

	local connection
	connection = humanoid.ApplyDescriptionFinished:Connect(function()
		connection:Disconnect()
	end)

	humanoid:applyDescription(description)
end

local function getUserOutfitIdFromBundleItems(bundleItems: {}): number?
	for _, item in ipairs(bundleItems) do
		if item.Type == "UserOutfit" then
			return item.Id
		end
	end
	return nil
end

-- Core functionality
function AvatarCustomisationService.RemoveAllAccessories(player: Player)
	local clonedDescription = getClonedDescription(player)

	-- Remove all accessories and body parts
	for _, description in ipairs(clonedDescription:GetChildren()) do
		if description:IsA("AccessoryDescription") or description:IsA("BodyPartDescription") then
			description:Destroy()
		end
	end

	AvatarCustomisationService.applyDescription(player, clonedDescription)
end  

function AvatarCustomisationService.AddAccessoryToAvatar(player: Player, itemId: number, assetType: string)


	local clonedDescription = getClonedDescription(player)

	local accessoryDescription = Instance.new("AccessoryDescription")
	accessoryDescription.AssetId = itemId
	accessoryDescription.AccessoryType = Enum.AccessoryType[GetAccessoryTypeFromAssetType(assetType)]

	-- TODO: Give this a cleaner implementation
	if PlayerHasMaxOfAccessoryTypeEquipped(player, accessoryDescription.AccessoryType) then
		if accessoryDescription.AccessoryType == Enum.AccessoryType.Hat then
			warn("Cannot equip more than 3 hats!")
			return
		else
			warn("Maxxed out! Deleting previous one...`")
			for _, description in ipairs(clonedDescription:GetChildren()) do
				if description:IsA("AccessoryDescription") and description.AccessoryType == accessoryDescription.AccessoryType then
					description:Destroy()
				end
			end
		end
	else
		print("Equipping ", itemId)
	end
	
	accessoryDescription.IsLayered = true
	accessoryDescription.Order = 1
	accessoryDescription.Parent = clonedDescription
 
	AvatarCustomisationService.applyDescription(player, clonedDescription)
end

-- TODO: This is a little redundant, consider optimising...
function AvatarCustomisationService.ApplyOutfitToAvatar(player: Player, outfitId: number)
	local success, outfitDescription = pcall(function()
		return Players:GetHumanoidDescriptionFromOutfitId(outfitId)
	end)

	if success then
		AvatarCustomisationService.applyDescription(player, outfitDescription)
	else
		warn("Failed to get outfit description for ID:", outfitId)
	end
end

function AvatarCustomisationService.AddBundleToAvatar(player: Player, bundleId: number, bundleType: string)
	-- Clear existing accessories first
	
	AvatarCustomisationService.RemoveAllAccessories(player)

	local success, bundleInfo = pcall(function()
		return MarketplaceService:GetProductInfo(bundleId, Enum.InfoType.Bundle)
	end)

	if not success then
		warn("Failed to get bundle details for ID:", bundleId)
		return
	end

	if bundleType == Enum.BundleType.BodyParts.Name then
		local bundleItems = bundleInfo.Items

		-- Check for UserOutfit first (simpler approach)
		local userOutfitId = getUserOutfitIdFromBundleItems(bundleItems)
		if userOutfitId then
			local success, outfitDescription = pcall(function()
				return Players:GetHumanoidDescriptionFromOutfitId(userOutfitId)
			end)

			if success then
				AvatarCustomisationService.applyDescription(player, outfitDescription)
				return
			else
				warn("Failed to get outfit description for ID:", userOutfitId)
			end
		end

		-- Fallback: Add individual items
		for _, item in ipairs(bundleItems) do
			if item.Type ~= "UserOutfit" then
				AvatarCustomisationService.AddAccessoryToAvatar(player, item.Id, item.Type)
			end
		end
	else
		warn("Unsupported bundle type:", bundleType)
	end
end

-- Public API
function AvatarCustomisationService.AddItemToAvatar(player: Player, itemId: number, assetOrBundleType: string, itemType: string)
	if itemType == "Asset" then
		AvatarCustomisationService.AddAccessoryToAvatar(player, itemId, assetOrBundleType)
	elseif itemType == "Bundle" then
		AvatarCustomisationService.AddBundleToAvatar(player, itemId, assetOrBundleType)
	else
		warn("Invalid item type:", itemType, "Expected 'Asset' or 'Bundle'")
	end
end

function AvatarCustomisationService.RemoveItemFromAvatar(player: Player, itemId: number)
	local clonedDescription = getClonedDescription(player)
	local itemDescription = findItemDescription(clonedDescription, itemId)

	if not itemDescription then
		warn("Item", itemId, "not found on player", player.Name)
		return false
	end

	if itemDescription:IsA("AccessoryDescription") then
		itemDescription:Destroy()
	elseif itemDescription:IsA("BodyPartDescription") then
		itemDescription.AssetId = 0
		itemDescription.Color = DEFAULT_BODY_COLOR
	else
		warn("Unknown description type for item", itemId)
		return false
	end

	AvatarCustomisationService.applyDescription(player, clonedDescription)
	return true
end

function AvatarCustomisationService.IsWearingItem(player: Player, itemId: number): boolean
	local humanoid = GetHumanoidFromPlayer(player)
	local humanoidDescription = humanoid:WaitForChild("HumanoidDescription") :: HumanoidDescription
	return findItemDescription(humanoidDescription, itemId) ~= nil
end

function AvatarCustomisationService.GetWornItems(player: Player): {number}
	local humanoid = GetHumanoidFromPlayer(player)
	local humanoidDescription = humanoid:WaitForChild("HumanoidDescription") :: HumanoidDescription

	local wornItems = {}
	for _, description in pairs(humanoidDescription:GetChildren()) do
		if description.AssetId and description.AssetId > 0 then
			table.insert(wornItems, description.AssetId)
		end
	end

	return wornItems
end

return AvatarCustomisationService