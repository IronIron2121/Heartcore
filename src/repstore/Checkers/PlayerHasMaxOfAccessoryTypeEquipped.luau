--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Getters = ReplicatedStorage:WaitForChild("Getters")

-- Modules
local GetWearLimitFromAccessoryType = require(Getters:WaitForChild("GetWearLimitFromAccessoryType"))
local GetNumberOfAccessoryTypeEquipped = require(Getters:WaitForChild("GetNumberOfAccessoryTypeEquipped"))

function PlayerHasMaxOfAccessoryTypeEquipped(player: Player, accessoryType: Enum.AccessoryType)
    if not accessoryType then
        assert("Player equipped item with non-existent accessory type")
    end

    local accessoryWearLimit = GetWearLimitFromAccessoryType(accessoryType.Name)
    local numEquipped = GetNumberOfAccessoryTypeEquipped(player, accessoryType)

    if not accessoryWearLimit or not numEquipped then
        warn("bad value")
        assert("Something has gone wrong here")
    end

    print(accessoryWearLimit, numEquipped)
    return accessoryWearLimit <= numEquipped 
end

return PlayerHasMaxOfAccessoryTypeEquipped 