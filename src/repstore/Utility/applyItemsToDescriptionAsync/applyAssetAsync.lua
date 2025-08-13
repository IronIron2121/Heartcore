--!strict

--[[
	applyAssetAsync - This function updates HumanoidDescription properties to add an asset to it. Some assets have a direct
	property mapping (e.g. body parts, classic clothing), while accessories are stored as an array that needs to be modified.

	The optional 'replace' parameter has accessories in the same category (e.g. tops/bottoms) be replaced, to allow easy
	swapping out of items when trying them on.
--]]

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDetailsCache = require(ReplicatedStorage.Libraries.ItemDetailsCache) 
local removeSimilarAccessories = require(script.Parent.removeSimilarAccessories)

local DIRECT_MAPPINGS = {
	"Head",
	"Torso",
	"RightArm",
	"LeftArm",
	"RightLeg",
	"LeftLeg",
	"MoodAnimation",
	"ClimbAnimation",
	"FallAnimation",
	"IdleAnimation",
	"JumpAnimation",
	"RunAnimation",
	"SwimAnimation",
	"WalkAnimation",
	"Shirt",
	"Pants",
	"Face",
}

local INDIRECT_MAPPINGS = {
	DynamicHead = "Head",
	TShirt = "GraphicTShirt",
}

-- Presumably for the order in which accessories are applied, or displayed
local ACCESSORY_ORDER = {
	[Enum.AccessoryType.RightShoe] = 1,
	[Enum.AccessoryType.LeftShoe] = 1,
	[Enum.AccessoryType.Pants] = 2,
	[Enum.AccessoryType.Shorts] = 2,
	[Enum.AccessoryType.DressSkirt] = 2,
	[Enum.AccessoryType.TShirt] = 3,
	[Enum.AccessoryType.Shirt] = 4,
	[Enum.AccessoryType.Sweater] = 5,
	[Enum.AccessoryType.Jacket] = 6,
}

local function applyAssetAsync(description: HumanoidDescription, assetId: number, replace: boolean?): HumanoidDescription?
	local assetDetails = ItemDetailsCache.getAssetDetailsAsync(assetId)
	if not assetDetails then
		warn(`Could not apply asset id {assetId}, failed to fetch details`)
		return description
	end
	
	-- We cast to any here to avoid a warning about dynamic property access.
	-- While dynamic property access is generally unsafe, we are using a static list of properties
	-- that we know are correct and won't break at runtime.
	
	-- This function instantly replaces old-school t-shirts/shirts/pants, and limb items as they are mutually exclusive
	-- Otherwise, with hats and accessories (of which players can have multiple), it [adds them to the humanoid? non-exclusively?]
	
	if table.find(DIRECT_MAPPINGS, assetDetails.AssetType) then
		(description :: any)[assetDetails.AssetType] = assetDetails.Id
	elseif INDIRECT_MAPPINGS[assetDetails.AssetType] then
		(description :: any)[INDIRECT_MAPPINGS[assetDetails.AssetType]] = assetDetails.Id
	elseif string.find(assetDetails.AssetType, "Accessory") or assetDetails.AssetType == "Hat" then
		-- For accessories and hats, we need to modify the list of accessories embedded in the HumanoidDescription
		local accessories = description:GetAccessories(true)
		local assetType = Enum.AvatarAssetType[assetDetails.AssetType]
		local accessoryType = AvatarEditorService:GetAccessoryType(assetType)
		local order = ACCESSORY_ORDER[accessoryType] or 1

		-- Hats are always allowed to be stacked, other items should be swapped out if replace = true
		if replace and accessoryType ~= Enum.AccessoryType.Hat then
			removeSimilarAccessories(accessoryType, accessories)
		end

		local accessory = {
			AssetId = assetId,
			AccessoryType = accessoryType,
			Order = order,
		}

		table.insert(accessories, accessory)
		description:SetAccessories(accessories, true)
	else
		warn(`No mapping for {assetDetails.AssetType}`)
		return nil
	end

	return description
end

return applyAssetAsync