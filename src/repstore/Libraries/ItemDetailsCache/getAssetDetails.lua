--!strict

--[[
	getAssetDetails - A utility function to return asset details using AvatarEditorService:GetItemDetails().
--]]

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Utility.Types)

local function getAssetDetails(assetId: number): Types.AssetDetails
	local assetDetails = AvatarEditorService:GetItemDetails(assetId, Enum.AvatarItemType.Asset)
	assert(assetDetails.ItemType == "Asset", "ItemType is not 'Asset'")

	return assetDetails
end

return getAssetDetails