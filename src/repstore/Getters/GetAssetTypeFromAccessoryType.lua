--!strict

local singularNames = {
	"Hat",
	
}

local function GetAssetTypeFromAccessoryType(accessoryType: string): Enum.AssetType?
	-- If it already contains "Accessory", try to convert directly
	if string.find(accessoryType, "Accessory") or table.find(singularNames, accessoryType) then
		return Enum.AssetType:FromName(accessoryType)
		
	end
	-- Otherwise, append "Accessory" and convert to enum
	local assetTypeName = accessoryType .. "Accessory"
	return Enum.AssetType:FromName(assetTypeName)
end

return GetAssetTypeFromAccessoryType