-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")

-- Module Scripts
local getMannequinFromId = require(GettersFolder:WaitForChild("getMannequinFromId"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local stringOfNumbersToArray = require(UtilityFolder:WaitForChild("stringOfNumbersToArray"))

function getListOfBundleIdsFromMannequin(player: Player, mannequinId: number)
	local mannequin = getMannequinFromId(player, mannequinId)
	local bundleIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE)
	local bundleIdsList = stringOfNumbersToArray(bundleIdsString)
	return bundleIdsList
end

return getListOfBundleIdsFromMannequin