--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Getters = ReplicatedStorage:WaitForChild("Getters")

-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))

function IsAssetAlreadyEquipped(player: Player, assetId: number): boolean
    if not assetId then
        assert("Player equipped item with non-existent accessory type")
    end

    local humanoidDescription = getHumanoidDescriptionFromPlayer(player)
    if not humanoidDescription then
        warn("No description!")
        return true
    end

    for _, description in ipairs(humanoidDescription:GetChildren()) do
        if (description:IsA("AccessoryDescription") or description:IsA("BodyPartDescription")) and description.AssetId == assetId then
            warn("Found a match!", assetId, description.AssetId)
            return true
        end
    end

    return false
end

return IsAssetAlreadyEquipped