--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local GetAssetTypeFromAccessoryType = require(Getters:WaitForChild("GetAssetTypeFromAccessoryType"))

local AvatarEditorService = game:GetService("AvatarEditorService")
local AvatarRules = AvatarEditorService:GetAvatarRules()
local WearableAssetTypes = AvatarRules["WearableAssetTypes"]

--

function GetWearLimitFromAccessoryType(accessoryType: string)
    local assetType = GetAssetTypeFromAccessoryType(accessoryType)

    for _, assetInfo in ipairs(WearableAssetTypes) do
        if assetInfo["Id"] == assetType.Value then
            return assetInfo["MaxNumber"]
        end
    end

	warn("Did not find limits for assetType", assetType)
	
    return nil
end

return GetWearLimitFromAccessoryType