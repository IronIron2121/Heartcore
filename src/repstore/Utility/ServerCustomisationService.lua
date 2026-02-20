--!strict
-- ServerCustomisationService - Handles adding, removing, and checking avatar items

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
local Emotes = ReplicatedStorage:WaitForChild("Emotes")

-- Modules
local getHumanoidDescriptionFromPlayer = require(ReplicatedStorage.Getters.getHumanoidDescriptionFromPlayer)
local PlayerHasMaxOfAccessoryTypeEquipped = require(Checkers:WaitForChild("PlayerHasMaxOfAccessoryTypeEquipped"))
local IsAssetAlreadyEquipped = require(Checkers.IsAssetAlreadyEquipped)
local GetAccessoryTypeFromAssetType = require(Getters:WaitForChild("GetAccessoryTypeFromAssetType"))
local GetHumanoidFromPlayer = require(Getters:WaitForChild("GetHumanoidFromPlayer"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))

-- Misc
local flipId = 134227711062993
local fallId = 131035550365656

local animPrefix = "rbxassetid://"

-- Accessory layering order by type (tops above bottoms)
local ACCESSORY_TYPE_ORDER = {
	[Enum.AccessoryType.LeftShoe] = 8,
	[Enum.AccessoryType.RightShoe] = 8,
	[Enum.AccessoryType.TShirt] = 7,
	[Enum.AccessoryType.Shirt] = 6,
	[Enum.AccessoryType.Sweater] = 5,
	[Enum.AccessoryType.Jacket] = 4,
	[Enum.AccessoryType.DressSkirt] = 3,
	[Enum.AccessoryType.Shorts] = 2,
	[Enum.AccessoryType.Pants] = 1,
}

local DEFAULT_ACCESSORY_ORDER = 1

--

local ServerCustomisationService = {}

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

function ServerCustomisationService.applyDescription(player: Player, description: HumanoidDescription)
	local humanoid = GetHumanoidFromPlayer(player)

	local success, err = callWithRetry(function()
		return humanoid:ApplyDescription(description)
	end)

	if success then
		-- For some reason, 2d clothing doesn't update locally unless something is added to the character
		local refresher = Instance.new("Pants", humanoid.Parent)
		refresher:Destroy()
		description:Destroy()
	else
		warn(err)
		return false
	end

	ServerCustomisationService.ApplyJumpAnim(player)

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

function ServerCustomisationService.getNumberOfItemsEquipped(player: Player)
	local num = 0
	local desc = getHumanoidDescriptionFromPlayer(player)
	if not desc then return 0 end

	for _, description in desc:GetChildren() do
		if (description:IsA("AccessoryDescription") or description:IsA("BodyPartDescription") and description.AssetId ~= 0) then
			num += 1
		end
	end
	
	for _, clothingType in Constants.CLASSIC_HUMANOID_CLOTHING_ASSET_TYPES do
		if desc[clothingType] and desc[clothingType] ~= 0 and desc[clothingType] ~= Constants.DEFAULT_CLASSIC_CLOTHING_IDS[clothingType] then
			num += 1
		end
	end

	return num
end

-- Core functionality
function ServerCustomisationService.RemoveAllAccessoriesFromPlayer(player: Player)
	local clonedDescription = getClonedDescription(player)

	ServerCustomisationService.RemoveAllAccessoriesFromDescription(clonedDescription)

	ServerCustomisationService.applyDescription(player, clonedDescription)
end  

function ServerCustomisationService.ResetPlayerOutfit(player: Player): boolean
	local originalHumanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
	local humanoid = GetHumanoidFromPlayer(player)

	if not originalHumanoidDescription or not humanoid then 
		warn("Failed to get player original outfit", originalHumanoidDescription, humanoid)
		return false
	end

	humanoid:ApplyDescriptionReset(originalHumanoidDescription)	

	return true
end

function ServerCustomisationService.ApplyInspectedOutfitToPlayer(player: Player, humanoidDescription: Player)
	local humanoid = GetHumanoidFromPlayer(player)
	local success = callWithRetry(function()  
		return humanoid:ApplyDescriptionAsync(humanoidDescription)
	end)

	return success
end

function ServerCustomisationService.AddAccessoryToAvatar(player: Player, itemId: number, assetType: string)
	local clonedDescription = getClonedDescription(player)

	local accessoryDescription = Instance.new("AccessoryDescription")
	accessoryDescription.AssetId = itemId
	accessoryDescription.AccessoryType = Enum.AccessoryType[GetAccessoryTypeFromAssetType(assetType)]

	-- Check if at max capacity for this accessory type
	if PlayerHasMaxOfAccessoryTypeEquipped(player, accessoryDescription.AccessoryType) then
		if accessoryDescription.AccessoryType == Enum.AccessoryType.Hat then
			print("Cannot equip more than 3 hats!") 
			return true
		else
			print("Maxed out! Deleting previous one...")
			for _, description in ipairs(clonedDescription:GetChildren()) do
				if description:IsA("AccessoryDescription") and description.AccessoryType == accessoryDescription.AccessoryType then
					description:Destroy()
				end
			end
		end
	end
	
	accessoryDescription.IsLayered = true
	accessoryDescription.Order = ACCESSORY_TYPE_ORDER[accessoryDescription.AccessoryType] or DEFAULT_ACCESSORY_ORDER
	accessoryDescription.Parent = clonedDescription

	return ServerCustomisationService.applyDescription(player, clonedDescription)
end

function ServerCustomisationService.AddAccessoriesToAvatar(player: Player, accessories: {{itemId: number, assetType: string}})
	local clonedDescription = getClonedDescription(player)

	for _, accessory in ipairs(accessories) do
		local accessoryDescription = Instance.new("AccessoryDescription")
		accessoryDescription.AssetId = accessory.itemId
		accessoryDescription.AccessoryType = Enum.AccessoryType[GetAccessoryTypeFromAssetType(accessory.assetType)]

		-- Check if at max capacity for this accessory type
		if PlayerHasMaxOfAccessoryTypeEquipped(player, accessoryDescription.AccessoryType) then
			if accessoryDescription.AccessoryType == Enum.AccessoryType.Hat then
				print("Cannot equip more than 3 hats!")
				continue
			else
				print("Maxed out! Deleting previous one...")
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
		accessoryDescription.Order = ACCESSORY_TYPE_ORDER[accessoryDescription.AccessoryType] or DEFAULT_ACCESSORY_ORDER
		accessoryDescription.Parent = clonedDescription
	end

	ServerCustomisationService.applyDescription(player, clonedDescription)
end

function ServerCustomisationService.ApplyJumpAnim(player: Player)
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local animator = hum:WaitForChild("Animator")
	for _, track in pairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end
	local animScript = char:WaitForChild("Animate")
	
	
	--All custom animations go here vvv --
	animScript.jump.JumpAnim.AnimationId = animPrefix .. tostring(flipId)
	animScript.fall.FallAnim.AnimationId = animPrefix .. tostring(fallId)
end

function ServerCustomisationService.AddBodyPartToAvatar(player: Player, itemId: number, bodyPartType: string)
	if not player or not itemId or not bodyPartType then 
		warn("Bad parameters at add bodypart!", player, itemId, bodyPartType)
		return false
	end

	local clonedDescription = getClonedDescription(player)

	-- Get the bodypart enum
	local bodyPartEnum = Enum.BodyPart:FromName(bodyPartType)

	if not bodyPartEnum and bodyPartType == "DynamicHead" then
		bodyPartEnum = Enum.BodyPart.Head
	elseif not bodyPartEnum then
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

	return ServerCustomisationService.applyDescription(player, clonedDescription)
end

function ServerCustomisationService.AddBodyPartsToAvatar(player: Player, bodyParts: {{itemId: number, bodyPartType: string}})
	if not player or not bodyParts then 
		warn("Bad parameters at add bodyparts!", player, bodyParts)
		return false
	end

	local clonedDescription = getClonedDescription(player)

	for _, bodyPart in ipairs(bodyParts) do
		-- TODO: Modularise this with the redundant code in above singular add body part function
		-- Get the bodypart enum

		local bodyPartEnum = Enum.BodyPart:FromName(bodyPart.bodyPartType)
		if not bodyPartEnum then
			warn("Bad bodypart type:", bodyPart.bodyPartType)
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

		-- Create and add new body part
		bodyPartDescription.AssetId = bodyPart.itemId
		bodyPartDescription.BodyPart = bodyPartEnum
		bodyPartDescription.Parent = clonedDescription
	end

	return ServerCustomisationService.applyDescription(player, clonedDescription)
end

function ServerCustomisationService.ApplyOutfitToAvatar(player: Player, outfitId: number)
	local success, outfitDescription = pcall(function()
		return Players:GetHumanoidDescriptionFromOutfitId(outfitId)
	end)

	if success then
		ServerCustomisationService.applyDescription(player, outfitDescription)
	else
		warn("Failed to get outfit description for ID:", outfitId)
	end
end

function ServerCustomisationService.AddBundleToAvatar(player: Player, bundleId: number, bundleType: string)
	local success, bundleInfo = callWithRetry(function()
		return AssetService:GetBundleDetailsAsync(bundleId)
	end, 3)

	if not success then
		warn("Failed to get bundle details for ID:", bundleId)
		return false
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
					return ServerCustomisationService.AddBodyPartToAvatar(player, item.Id, "Head")
				end
			end
		end
		return true
	end

	-- Handle Body Parts bundles
	if bundleInfo.BundleType == Enum.BundleType.BodyParts.Name or bundleInfo.BundleType == Enum.BundleType.Shoes.Name then
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
									bodyPartType = assetTypeName :: string
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
			ServerCustomisationService.AddBodyPartsToAvatar(player, bodyParts)
		end
		if #accessories > 0 then
			ServerCustomisationService.AddAccessoriesToAvatar(player, accessories)
		end
		return true
	end

	-- Check for UserOutfit (simpler approach for other bundle types)
	local userOutfitId = getUserOutfitIdFromBundleItems(bundleItems)
	if userOutfitId then
		local descSuccess, outfitDescription = pcall(function()
			return Players:GetHumanoidDescriptionFromOutfitId(userOutfitId)
		end)

		if descSuccess then
			return ServerCustomisationService.applyDescription(player, outfitDescription)
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
				ServerCustomisationService.AddAccessoryToAvatar(player, item.Id, assetInfo.AssetTypeId)
			end
		end
	end

	return true
end

function ServerCustomisationService.AddClassicClothingToAvatar(player: Player, itemId: number, assetType: string)
	local clonedDescription = getClonedDescription(player)

	if assetType == "TShirt" then
		clonedDescription.GraphicTShirt = itemId
	elseif assetType == "Shirt" then
		clonedDescription.Shirt = itemId 
	elseif assetType == "Pants" then 
		clonedDescription.Pants = itemId
	elseif assetType == "Face" then 
		clonedDescription.Face = itemId
	end

	return ServerCustomisationService.applyDescription(player, clonedDescription)
end

function ServerCustomisationService.LoadEmote(itemId: number): Animation?
	local emote = Emotes:FindFirstChild(tostring(itemId)) :: Animation?
	if emote then
		return emote
	end

	local asset = InsertService:LoadAsset(itemId)
	emote = asset:FindFirstChildWhichIsA("Animation", true)
	if emote then
		emote:ClearAllChildren()
		emote.Name = tostring(itemId)
		emote.Parent = Emotes
	end
	asset:Destroy()

	return emote
end

function ServerCustomisationService.TryEmote(player: Player, itemId: number): boolean
	local humanoid = GetHumanoidFromPlayer(player)
	local emote = ServerCustomisationService.LoadEmote(itemId)
	if not emote then return false end

	local animator = humanoid:FindFirstChild("Animator") :: Animator?

	local newTrack : AnimationTrack
	if animator then
		for _, previousTrack in animator:GetPlayingAnimationTracks() do
			previousTrack:Stop()
			previousTrack:Destroy()
		end

		newTrack = animator:LoadAnimation(emote)
	end

	if newTrack then
		newTrack.Looped = true
		newTrack:Play()
		task.spawn(function()
			local detector = humanoid:GetPropertyChangedSignal("MoveDirection")
			detector:Connect(function()
				newTrack:Stop()
				detector = nil
			end)
		end)
	end

	return true
end

-- Public API

function ServerCustomisationService.RemoveAllAccessoriesFromDescription(description: HumanoidDescription)
	for _, child in ipairs(description:GetChildren()) do
		if child:IsA("AccessoryDescription") then
			child:Destroy()
		end
	end
	for _, prop in ipairs(Constants.CLASSIC_HUMANOID_ACCESSORIES) do
		description[prop] = Constants.DEFAULT_CLASSIC_CLOTHING_IDS[prop]
	end
end

function ServerCustomisationService.ApplyInspectedItemsToPlayer(
	player: Player,
	items: {{ itemId: number, assetOrBundleType: string, itemType: string }}
)
	local clonedDescription = getClonedDescription(player)
	--ServerCustomisationService.RemoveAllAccessoriesFromDescription(clonedDescription)

	local emoteIds = {}
	local bundleItems = {}

	for _, item in ipairs(items) do
		if item.itemType == "Asset" and table.find(Constants.CLASSIC_CLOTHING_ASSET_TYPES, item.assetOrBundleType) then
			if item.assetOrBundleType == "TShirt" then
				clonedDescription.GraphicTShirt = item.itemId
			elseif item.assetOrBundleType == "Shirt" then
				clonedDescription.Shirt = item.itemId
			elseif item.assetOrBundleType == "Pants" then
				clonedDescription.Pants = item.itemId
			elseif item.assetOrBundleType == "Face" then
				clonedDescription.Face = item.itemId
			end

		elseif item.itemType == "Asset" and item.assetOrBundleType == Constants.EMOTE_ASSET_TYPE then
			table.insert(emoteIds, item.itemId)

		elseif item.itemType == "Asset" and Enum.BodyPart:FromName(item.assetOrBundleType) then
			local bodyPartEnum = Enum.BodyPart[item.assetOrBundleType]
			local bodyPartDescription = Instance.new("BodyPartDescription")
			for _, desc in ipairs(clonedDescription:GetChildren()) do
				if desc:IsA("BodyPartDescription") and desc.BodyPart == bodyPartEnum then
					bodyPartDescription.Color = desc.Color
					desc:Destroy()
				end
			end

			bodyPartDescription.AssetId = item.itemId
			bodyPartDescription.BodyPart = bodyPartEnum
			bodyPartDescription.Parent = clonedDescription

		elseif item.itemType == "Asset" then
			local accessoryDescription = Instance.new("AccessoryDescription")
			accessoryDescription.AssetId = item.itemId
			accessoryDescription.AccessoryType = Enum.AccessoryType[GetAccessoryTypeFromAssetType(item.assetOrBundleType)]
			accessoryDescription.IsLayered = true
			accessoryDescription.Order = ACCESSORY_TYPE_ORDER[accessoryDescription.AccessoryType] or DEFAULT_ACCESSORY_ORDER
			accessoryDescription.Parent = clonedDescription
			
		elseif item.itemType == "Bundle" then
			table.insert(bundleItems, item)
		end
	end

	ServerCustomisationService.applyDescription(player, clonedDescription)

	for _, emoteId in ipairs(emoteIds) do
		ServerCustomisationService.TryEmote(player, emoteId)
	end

	for _, item in ipairs(bundleItems) do
		ServerCustomisationService.AddBundleToAvatar(player, item.itemId, item.assetOrBundleType)
	end
end

-- Batch version of AddItemToAvatar: clones description once, applies all items, then applies once
function ServerCustomisationService.AddItemsToAvatar(
	player: Player,
	items: {{ itemId: number, assetOrBundleType: string, itemType: string }}
)
	local clonedDescription = getClonedDescription(player)
	local emoteIds = {}
	local bundleItems = {}

	for _, item in ipairs(items) do
		if IsAssetAlreadyEquipped(player, item.itemId) then
			continue
		end

		if item.itemType == "Asset" and table.find(Constants.CLASSIC_CLOTHING_ASSET_TYPES, item.assetOrBundleType) then
			if item.assetOrBundleType == "TShirt" then
				clonedDescription.GraphicTShirt = item.itemId
			elseif item.assetOrBundleType == "Shirt" then
				clonedDescription.Shirt = item.itemId
			elseif item.assetOrBundleType == "Pants" then
				clonedDescription.Pants = item.itemId
			elseif item.assetOrBundleType == "Face" then
				clonedDescription.Face = item.itemId
			end

		elseif item.itemType == "Asset" and item.assetOrBundleType == Constants.EMOTE_ASSET_TYPE then
			table.insert(emoteIds, item.itemId)

		elseif item.itemType == "Asset" and (Enum.BodyPart:FromName(item.assetOrBundleType) or item.assetOrBundleType == Enum.AssetType.DynamicHead.Name) and item.assetOrBundleType ~= "Face" then
			local bodyPartEnum = Enum.BodyPart:FromName(item.assetOrBundleType)
			if not bodyPartEnum then 
				bodyPartEnum = Enum.BodyPart.Head
			end

			local bodyPartDescription = Instance.new("BodyPartDescription")
			for _, desc in ipairs(clonedDescription:GetChildren()) do
				if desc:IsA("BodyPartDescription") and desc.BodyPart == bodyPartEnum then
					bodyPartDescription.Color = desc.Color
					desc:Destroy()
				end
			end
			bodyPartDescription.AssetId = item.itemId
			bodyPartDescription.BodyPart = bodyPartEnum
			bodyPartDescription.Parent = clonedDescription

		elseif item.itemType == "Asset" and item.assetOrBundleType ~= "Face" then
			local accessoryDescription = Instance.new("AccessoryDescription")
			accessoryDescription.AssetId = item.itemId
			accessoryDescription.AccessoryType = Enum.AccessoryType[GetAccessoryTypeFromAssetType(item.assetOrBundleType)]

			if PlayerHasMaxOfAccessoryTypeEquipped(player, accessoryDescription.AccessoryType) then
				if accessoryDescription.AccessoryType == Enum.AccessoryType.Hat then
					continue
				else
					for _, desc in ipairs(clonedDescription:GetChildren()) do
						if desc:IsA("AccessoryDescription") and desc.AccessoryType == accessoryDescription.AccessoryType then
							desc:Destroy()
						end
					end
				end
			end

			accessoryDescription.IsLayered = true
			accessoryDescription.Order = ACCESSORY_TYPE_ORDER[accessoryDescription.AccessoryType] or DEFAULT_ACCESSORY_ORDER
			accessoryDescription.Parent = clonedDescription

		elseif item.itemType == "Bundle" then
			table.insert(bundleItems, item)
		end
	end

	ServerCustomisationService.applyDescription(player, clonedDescription)

	for _, emoteId in ipairs(emoteIds) do
		ServerCustomisationService.TryEmote(player, emoteId)
	end

	for _, item in ipairs(bundleItems) do
		ServerCustomisationService.AddBundleToAvatar(player, item.itemId, item.assetOrBundleType)
	end
end

function ServerCustomisationService.AddItemToAvatar(player: Player, itemId: number, assetOrBundleType: string, itemType: string)
	if IsAssetAlreadyEquipped(player, itemId) then 
		warn("Item already equipped")
		return false
	end

	if itemType == "Asset" and table.find(Constants.CLASSIC_CLOTHING_ASSET_TYPES, assetOrBundleType) then
		return ServerCustomisationService.AddClassicClothingToAvatar(player, itemId, assetOrBundleType)
	elseif itemType == "Asset" and assetOrBundleType == Constants.EMOTE_ASSET_TYPE then
		return ServerCustomisationService.TryEmote(player, itemId)
	elseif itemType == "Asset" and (Enum.BodyPart:FromName(assetOrBundleType) or assetOrBundleType == Enum.AssetType.DynamicHead.Name) then
		return ServerCustomisationService.AddBodyPartToAvatar(player, itemId, assetOrBundleType)
	elseif itemType == "Asset" then
		return ServerCustomisationService.AddAccessoryToAvatar(player, itemId, assetOrBundleType)
	elseif itemType == "Bundle" then
		return ServerCustomisationService.AddBundleToAvatar(player, itemId, assetOrBundleType)
	else
		warn("Invalid item type:", itemType, "Expected 'Asset' or 'Bundle'")
		return false
	end
end

function ServerCustomisationService.RemoveItemFromAvatar(player: Player, itemId: number)
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

	ServerCustomisationService.applyDescription(player, clonedDescription)
	return true
end

function ServerCustomisationService.RemoveClassicClothingFromAvatar(player: Player, itemId: number, itemType: string)
	local defaultId = Constants.DEFAULT_CLASSIC_CLOTHING_IDS[itemType]

	if not defaultId then 
		warn("Invalid classic clothing type:", itemType) 
		return false
	end

	local clonedDescription = getClonedDescription(player)
	clonedDescription[itemType] = defaultId

	ServerCustomisationService.applyDescription(player, clonedDescription)

	return true
end

function ServerCustomisationService.IsWearingItem(player: Player, itemId: number): boolean
	local humanoid = GetHumanoidFromPlayer(player)
	local humanoidDescription = humanoid:WaitForChild("HumanoidDescription") :: HumanoidDescription
	return findItemDescription(humanoidDescription, itemId) ~= nil
end

function ServerCustomisationService.GetWornItems(player: Player): {number}
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

return ServerCustomisationService