--!strict

--[[
	ItemDetailsCache - This module implements caching for asset and bundle details returned by
	AvatarEditorService:GetItemDetails().

	A function to ingest item details is also provided. This is used when searching the catalog,
	as AvatarEditorService:SearchCatalog() returns item details in bulk which must then be cached.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Utility.Types)
local Cache = require(ReplicatedStorage.Utility.Cache)

local getAssetDetails = require(script.getAssetDetails)
local getBundleDetails = require(script.getBundleDetails)

local CACHE_TIME_SECONDS = 60 * 3 -- 3 minutes

-- Create two caches to store details for assets and bundles, this avoids us having to make constant web calls
local assetCache = Cache.new(getAssetDetails, CACHE_TIME_SECONDS)
local bundleCache = Cache.new(getBundleDetails, CACHE_TIME_SECONDS)

local ItemDetailsCache = {}

function ItemDetailsCache.getAssetDetailsAsync(assetId: number, forceRefresh: boolean?): Types.AssetDetails?
	return assetCache:get(assetId, forceRefresh)
end

function ItemDetailsCache.getBundleDetailsAsync(bundleId: number, forceRefresh: boolean?): Types.BundleDetails?
	return bundleCache:get(bundleId, forceRefresh)
end

-- Add item details either to the assetCache or bundleCache, based on the specified ItemType
function ItemDetailsCache.ingestItemDetails(itemDetails: Types.ItemDetails)
	if itemDetails.ItemType == "Asset" then
		assetCache:set(itemDetails.Id, itemDetails :: Types.AssetDetails)
	elseif itemDetails.ItemType == "Bundle" then
		bundleCache:set(itemDetails.Id, itemDetails :: Types.BundleDetails)
	else
		error(`Unknown item type: {itemDetails.ItemType}`)
	end
end

return ItemDetailsCache
