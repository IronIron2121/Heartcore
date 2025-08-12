local function GetAccessoryTypeFromAssetType(assetType: string)
	return string.gsub(assetType, "Accessory", "")
end

return GetAccessoryTypeFromAssetType
