--!strict

--[[
	applyItemsToDescriptionAsync - A utility function to apply a list of assets and a list of bundles to a HumanoidDescription.

	The optional 'replace' parameter has accessories in the same category (e.g. tops/bottoms) be replaced, to allow easy
	swapping out of items when trying them on.
	
	TODO: Erase this entirely!
--]]

local applyAssetAsync = require(script.applyAssetAsync)
local applyBundleAsync = require(script.applyBundleAsync)

local function applyItemsToDescriptionAsync(
	description: HumanoidDescription,
	assetIds: { number },
	bundleIds: { number },
	replace: boolean?
): HumanoidDescription
	-- Apply bundles
	for _, bundleId in bundleIds do
		applyBundleAsync(description, bundleId, replace)
	end

	-- Apply assets
	for _, assetId in assetIds do
		applyAssetAsync(description, assetId, replace)
	end

	return description
end

return applyItemsToDescriptionAsync
