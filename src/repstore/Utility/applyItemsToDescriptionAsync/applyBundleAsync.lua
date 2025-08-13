--!strict

--[[
	applyBundleAsync - This function applies all bundled assets in a bundle to a HumanoidDescription.

	The optional 'replace' parameter has accessories in the same category (e.g. tops/bottoms) be replaced, to allow easy
	swapping out of items when trying them on.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDetailsCache = require(ReplicatedStorage.Libraries.ItemDetailsCache)
local applyAssetAsync = require(script.Parent.applyAssetAsync)

local function applyBundleAsync(
	description: HumanoidDescription,
	bundleId: number,
	replace: boolean?
): HumanoidDescription
	local bundleDetails = ItemDetailsCache.getBundleDetailsAsync(bundleId)
	if not bundleDetails then
		warn(`Could not apply bundle id {bundleId}, failed to fetch details`)
		return description
	end

	for _, bundledItem in bundleDetails.BundledItems do
		if bundledItem.Type ~= "Asset" then
			warn(`Unable to apply bundled item type: {bundledItem.Type}`)
			continue
		end

		applyAssetAsync(description, bundledItem.Id, replace)
	end

	return description
end

return applyBundleAsync
