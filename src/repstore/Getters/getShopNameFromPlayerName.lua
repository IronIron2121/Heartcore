-- Services
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")

-- Folders
local GettersFolder 			= ReplicatedStorage:WaitForChild("Getters")

-- Module scripts
local Constants 				= require(ReplicatedStorage.Constants)
local getPlayerFromPlayerName 	= GettersFolder:WaitForChild("getPlayerFromPlayerName")

function getShopNameFromPlayer(playerName: string)
	if not playerName then return nil end
	
	local player = getPlayerFromPlayerName(playerName)
	if not player then 
		return nil 
	else 
		return player:GetAttribute(Constants.PLAYER_CLAIM_ATTRIBUTES.SHOP_NAME)
	end
end

return getShopNameFromPlayer
