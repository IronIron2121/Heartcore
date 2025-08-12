-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")

-- Module Scripts
local getMannequinFromId = require(GettersFolder:WaitForChild("getMannequinFromId"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local stringOfNumbersToArray = require(UtilityFolder:WaitForChild("stringOfNumbersToArray"))

function getListOfAccessoryIdsFromMannequin(player: Player, mannequinId: number)
	local mannequin = getMannequinFromId(player, mannequinId)
	local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local accessoryIdsList = stringOfNumbersToArray(accessoryIdsString)
	return accessoryIdsList
end

return getListOfAccessoryIdsFromMannequin
