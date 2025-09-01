--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Getters = ReplicatedStorage:WaitForChild("Getters")

-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))

-- TODO: Get a faster way of accessing player humanoid description maybe
function GetNumberOfAccessoryTypeEquipped(player: Player, accessoryType: Enum.AccessoryType): number?
    local humanoidDescription = getHumanoidDescriptionFromPlayer(player)
    if not humanoidDescription then
        warn("No description!")
        return nil
    end
    local descriptions = humanoidDescription:GetChildren()
    if not descriptions then
        warn("No accessory descriptions!")
    end

    local numEquipped = 0
    for _, description in ipairs(descriptions) do
        if description:IsA("AccessoryDescription") then
            if accessoryType == description.AccessoryType then
                numEquipped += 1
            end
        end
    end

    return numEquipped
end

return GetNumberOfAccessoryTypeEquipped