--!strict
-- AvatarCustomisationService - Handles adding, removing, and checking avatar items

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")

-- Folders
local Checkers = ReplicatedStorage:WaitForChild("Checkers")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Emotes = Instance.new("Folder", ReplicatedStorage)
Emotes.Name = "Emotes"

-- Modules
local PlayerHasMaxOfAccessoryTypeEquipped = require(Checkers:WaitForChild("PlayerHasMaxOfAccessoryTypeEquipped"))
local GetAccessoryTypeFromAssetType = require(Getters:WaitForChild("GetAccessoryTypeFromAssetType"))
local GetHumanoidFromPlayer = require(Getters:WaitForChild("GetHumanoidFromPlayer"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Constants
local DEFAULT_BODY_COLOR = Color3.fromRGB(200, 200, 200)

--

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

	humanoid:ApplyDescription(description)

	-- For some reason, 2d clothing doesn't update locally unless something is added to the character
	local refresher = Instance.new("Pants", humanoid.Parent)
	refresher:Destroy()
	description:Destroy()

	return true
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

function AvatarCustomisationService.ResetPlayerOutfit(player: Player): boolean
	local originalHumanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
	local humanoid = GetHumanoidFromPlayer(player)

	if not originalHumanoidDescription or not humanoid then 
		warn("Failed to get player original outfit", originalHumanoidDescription, humanoid)
		return false
	end

	humanoid:ApplyDescriptionReset(originalHumanoidDescription)	

	return true
end

function AvatarCustomisationService.AddAccessoryToAvatar(player: Player, itemId: number, assetType: string)
	local clonedDescription = getClonedDescription(player)

	local accessoryDescription = Instance.new("AccessoryDescription")
	accessoryDescription.AssetId = itemId
	accessoryDescription.AccessoryType = Enum.AccessoryType[GetAccessoryTypeFromAssetType(assetType)]

	-- Check if at max capacity for this accessory type
	if PlayerHasMaxOfAccessoryTypeEquipped(player, accessoryDescription.AccessoryType) then
		if accessoryDescription.AccessoryType == Enum.AccessoryType.Hat then
			warn("Cannot equip more than 3 hats!")
			return
		else
			warn("Maxed out! Deleting previous one...")
			for _, description in ipairs(clonedDescription:GetChildren()) do
				if description:IsA("AccessoryDescription") and description.AccessoryType == accessoryDescription.AccessoryType then
					description:Destroy()
				end
			end
		end
	else
		print("Equipping", itemId)
	end
	
	accessoryDescription.IsLayered = true
	accessoryDescription.Order = 1
	accessoryDescription.Parent = clonedDescription

	AvatarCustomisationService.applyDescription(player, clonedDescription)
end

function AvatarCustomisationService.AddAccessoriesToAvatar(player: Player, accessories: {{itemId: number, assetType: string}})
	local clonedDescription = getClonedDescription(player)

	for _, accessory in ipairs(accessories) do
		local accessoryDescription = Instance.new("AccessoryDescription")
		accessoryDescription.AssetId = accessory.itemId
		accessoryDescription.AccessoryType = Enum.AccessoryType[GetAccessoryTypeFromAssetType(accessory.assetType)]

		-- Check if at max capacity for this accessory type
		if PlayerHasMaxOfAccessoryTypeEquipped(player, accessoryDescription.AccessoryType) then
			if accessoryDescription.AccessoryType == Enum.AccessoryType.Hat then
				warn("Cannot equip more than 3 hats!")
				continue
			else
				warn("Maxed out! Deleting previous one...")
				for _, description in ipairs(clonedDescription:GetChildren()) do
					if description:IsA("AccessoryDescription") and description.AccessoryType == accessoryDescription.AccessoryType then
						description:Destroy()
					end
				end
			end
		else
			print("Equipping", accessory.itemId)
		end

		accessoryDescription.IsLayered = true
		accessoryDescription.Order = 1
		accessoryDescription.Parent = clonedDescription
	end

	AvatarCustomisationService.applyDescription(player, clonedDescription)
end

function AvatarCustomisationService.AddBodyPartToAvatar(player: Player, itemId: number, bodyPartType: string)
	if not player or not itemId or not bodyPartType then 
		warn("Bad parameters at add bodypart!", player, itemId, bodyPartType)
		return false
	end

	local clonedDescription = getClonedDescription(player)

	-- Get the bodypart enum
	local bodyPartEnum = Enum.BodyPart[bodyPartType]
	if not bodyPartEnum then
		warn("Bad bodypart type:", bodyPartType)
		return false
	end

	-- Remove existing body part on the same slot after copying its colours
	local bodyPartDescription = Instance.new("BodyPartDescription")
	for _, description in ipairs(clonedDescription:GetChildren()) do
		if description:IsA("BodyPartDescription") and description.BodyPart == bodyPartEnum then
			bodyPartDescription.Color = description.Color
			description:Destroy()
		end
	end

	bodyPartDescription.AssetId = itemId
	bodyPartDescription.BodyPart = bodyPartEnum
	bodyPartDescription.Parent = clonedDescription

	return AvatarCustomisationService.applyDescription(player, clonedDescription)
end

function AvatarCustomisationService.AddBodyPartsToAvatar(player: Player, bodyParts: {{itemId: number, bodyPartType: string}})
	if not player or not bodyParts then 
		warn("Bad parameters at add bodyparts!", player, bodyParts)
		return false
	end

	local clonedDescription = getClonedDescription(player)

	for _, bodyPart in ipairs(bodyParts) do
		-- TODO: Modularise this with the redundant code in above singular add body part function
		-- Get the bodypart enum
		warn("equipping", bodyPart)

		local bodyPartEnum = Enum.BodyPart[bodyPart.bodyPartType]
		if not bodyPartEnum then
			warn("Bad bodypart type:", bodyPart.bodyPartType)
			continue
		end

		-- Remove existing body part on the same slot after copying its colours
		local bodyPartDescription = Instance.new("BodyPartDescription")
		for _, description in ipairs(clonedDescription:GetChildren()) do
			if description:IsA("BodyPartDescription") and description.BodyPart == bodyPartEnum then
				bodyPartDescription.Color = description.Color
				description:Destroy()
			end
		end

		-- Create and add new body part
		bodyPartDescription.AssetId = bodyPart.itemId
		bodyPartDescription.BodyPart = bodyPartEnum
		bodyPartDescription.Parent = clonedDescription
	end

	return AvatarCustomisationService.applyDescription(player, clonedDescription)
end

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
	local success, bundleInfo = callWithRetry(function()
		return AssetService:GetBundleDetailsAsync(bundleId)
	end, 3)

	if not success then
		warn("Failed to get bundle details for ID:", bundleId)
		return
	end

	local bundleItems = bundleInfo.Items

	-- Handle Dynamic Head bundles
	if bundleInfo.BundleType == Enum.BundleType.DynamicHead.Name then
		for _, item in ipairs(bundleItems) do
			if item.Type ~= "UserOutfit" then
				local assetSuccess, assetInfo = callWithRetry(function()
					return MarketplaceService:GetProductInfo(item.Id, Enum.InfoType.Asset)
				end, 3)

				-- AssetTypeId 79 is DynamicHead
				if assetSuccess and assetInfo and assetInfo.AssetTypeId == 79 then
					AvatarCustomisationService.AddBodyPartToAvatar(player, item.Id, "Head")
					return
				end
			end
		end
		return
	end

	-- Handle Body Parts bundles
	if bundleInfo.BundleType == Enum.BundleType.BodyParts.Name then
		local bodyParts = {}
		local accessories = {}
		
		for _, item in ipairs(bundleItems) do
			if item.Type ~= "UserOutfit" then
				local assetSuccess, assetInfo = callWithRetry(function()
					return MarketplaceService:GetProductInfo(item.Id, Enum.InfoType.Asset)
				end, 3)

				if assetSuccess and assetInfo then
					if assetInfo.AssetTypeId == 19 then
						warn("Item is a gear! Skipping equip...")
						continue
					elseif assetInfo.AssetTypeId == 79 then
						table.insert(bodyParts, {
							itemId = item.Id,
							bodyPartType = Enum.BodyPart.Head.Name
						})
					elseif table.find(Constants.ANIMATION_ASSET_TYPE_IDS, assetInfo.AssetTypeId) then
						warn("Item is an animation! Skipping equip...")
						continue
					else
						-- Check if it's a body part or accessory
						local assetTypeEnum = Enum.AssetType:FromValue(assetInfo.AssetTypeId)
						if assetTypeEnum then
							local assetTypeName = assetTypeEnum.Name
							-- Body part asset types
							if assetTypeName == "LeftArm" or assetTypeName == "RightArm" 
								or assetTypeName == "LeftLeg" or assetTypeName == "RightLeg" 
								or assetTypeName == "Torso" or assetTypeName == "Head" then
								table.insert(bodyParts, {
									itemId = item.Id,
									bodyPartType = assetTypeName
								})
							else
								-- It's an accessory
								table.insert(accessories, {
									itemId = item.Id,
									assetType = assetTypeName
								})
							end
						else
							warn("Failed to get assetType for", assetTypeEnum)
						end
					end
				end
			end
		end

		if #bodyParts > 0 then
			AvatarCustomisationService.AddBodyPartsToAvatar(player, bodyParts)
		end
		if #accessories > 0 then
			AvatarCustomisationService.AddAccessoriesToAvatar(player, accessories)
		end
		return
	end

	-- Check for UserOutfit (simpler approach for other bundle types)
	local userOutfitId = getUserOutfitIdFromBundleItems(bundleItems)
	if userOutfitId then
		local descSuccess, outfitDescription = pcall(function()
			return Players:GetHumanoidDescriptionFromOutfitId(userOutfitId)
		end)

		if descSuccess then
			AvatarCustomisationService.applyDescription(player, outfitDescription)
			return
		else
			warn("Failed to get outfit description for ID:", userOutfitId)
		end
	end

	-- Fallback: Add individual items as accessories
	for _, item in ipairs(bundleItems) do
		if item.Type ~= "UserOutfit" then
			local assetSuccess, assetInfo = callWithRetry(function()
				return MarketplaceService:GetProductInfo(item.Id, Enum.InfoType.Asset)
			end, 3)
			
			if assetSuccess and assetInfo then
				AvatarCustomisationService.AddAccessoryToAvatar(player, item.Id, assetInfo.AssetTypeId)
			end
		end
	end
end

function AvatarCustomisationService.AddClassicClothingToAvatar(player: Player, itemId: number, assetType: string)
	local clonedDescription = getClonedDescription(player)

	if assetType == "TShirt" then
		clonedDescription.GraphicTShirt = itemId
	elseif assetType == "Shirt" then
		clonedDescription.Shirt = itemId 
	elseif assetType == "Pants" then 
		clonedDescription.Pants = itemId
	end

	AvatarCustomisationService.applyDescription(player, clonedDescription)
end

function AvatarCustomisationService.TryEmote(player: Player, itemId: number)
	local humanoid = GetHumanoidFromPlayer(player)

	local asset = InsertService:LoadAsset(itemId)
	local emote = Emotes:FindFirstChild(tostring(itemId)) :: Animation

	if not emote then
		emote = asset:FindFirstChildWhichIsA("Animation", true)
		if emote then
			emote:ClearAllChildren()
			emote.Name = tostring(itemId)
			emote.Parent = Emotes
		end
	end

	asset:Destroy()

	local animator = humanoid:FindFirstChild("Animator") :: Animator?

	local track : AnimationTrack
	if animator then 
		track = animator:LoadAnimation(emote)
	end

	if track then
		track.Looped = false
		track:Play()
	end
end

-- Public API
function AvatarCustomisationService.AddItemToAvatar(player: Player, itemId: number, assetOrBundleType: string, itemType: string)
	if itemType == "Asset" and table.find(Constants.CLASSIC_CLOTHING_ASSET_TYPES, assetOrBundleType) then
		AvatarCustomisationService.AddClassicClothingToAvatar(player, itemId, assetOrBundleType)
	elseif itemType == "Asset" and assetOrBundleType == Constants.EMOTE_ASSET_TYPE then
		AvatarCustomisationService.TryEmote(player, itemId)
	elseif itemType == "Asset" then
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
	else
		warn("Unknown description type for item", itemId)
		return false
	end

	AvatarCustomisationService.applyDescription(player, clonedDescription)
	return true
end

function AvatarCustomisationService.RemoveClassicClothingFromAvatar(player: Player, itemId: number, itemType: string)
	local defaultId = Constants.DEFAULT_CLASSIC_CLOTHING_IDS[itemType]

	if not defaultId then 
		warn("Invalid classic clothing type:", itemType) 
		return false
	end

	local clonedDescription = getClonedDescription(player)
	clonedDescription[itemType] = defaultId

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