--!strict

--[[
	getBundleDetails - A utility function to return bundle details using AvatarEditorService:GetItemDetails().
--]]

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Utility.Types)

local function getBundleDetails(assetId: number): Types.BundleDetails
	local bundleDetails = AvatarEditorService:GetItemDetails(assetId, Enum.AvatarItemType.Bundle)
	assert(bundleDetails.ItemType == "Bundle", "ItemType is not 'Bundle'")

	return bundleDetails
end

return getBundleDetails
