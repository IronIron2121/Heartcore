--!strict

local function GetAccessoryTypeFromAssetTypeId(assetTypeId: number): string?
	local assetType = Enum.AssetType:FromValue(assetTypeId)
	
	if not assetType then
		warn("Asset type ID " .. assetTypeId .. " is not valid")
		return nil
	end
	
	local assetTypeString = assetType.Name
	return string.gsub(assetTypeString, "Accessory", "")
end

return GetAccessoryTypeFromAssetTypeId
