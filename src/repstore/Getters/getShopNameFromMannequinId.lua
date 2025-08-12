-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")

-- Module Scripts
local getMannequinFromId = require(GettersFolder:WaitForChild("getMannequinFromId"))


function getShopNameFromMannequinId(player: Player, mannequinId: number)
	local mannequin = getMannequinFromId(player, mannequinId)
	if not mannequin then
		return nil
	end
	return mannequin.Parent.Name
end
return getShopNameFromMannequinId
