--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local GetAssetTypeFromAccessoryType = require(Getters:WaitForChild("GetAssetTypeFromAccessoryType"))

local AvatarEditorService = game:GetService("AvatarEditorService")
local callWithRetry = require(ReplicatedStorage.Utility.callWithRetry)
local success, AvatarRules = callWithRetry(function()
    return AvatarEditorService:GetAvatarRules()
end)

warn(success)
warn(AvatarRules)

assert(success and AvatarRules, "Failed to get avatar rules!")


local WearableAssetTypes = AvatarRules["WearableAssetTypes"]

--

function GetWearLimitFromAccessoryType(accessoryType: string)
    local assetType = GetAssetTypeFromAccessoryType(accessoryType)

    for _, assetInfo in ipairs(WearableAssetTypes) do
        if assetInfo["Id"] == assetType.Value then
            return assetInfo["MaxNumber"]
        end
    end

    return nil
end

return GetWearLimitFromAccessoryType