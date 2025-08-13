--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")

-- Modules
local ItemDetailsCache = require(Libraries.ItemDetailsCache)


local MarketplaceUtilities = {}

function MarketplaceUtilities.getAssetTypeFromAssetId(assetId) : number?
	local itemDetails = ItemDetailsCache.getAssetDetailsAsync(assetId) or ItemDetailsCache.getBundleDetailsAsync(assetId)
	if not itemDetails then
		warn("Bad attempt to submit assetID - Asset Details Not Found")
		return nil
	end

	local productType = Enum.MarketplaceProductType[`Avatar{itemDetails.ItemType}`]
	
	return productType.Value
end

return MarketplaceUtilities
