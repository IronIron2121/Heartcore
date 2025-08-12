--!strict

--[[
	Returns true if player has claimed a shop and false if they haven't
]]

-- Services
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")

-- Folders 
local GettersFolder 			= ReplicatedStorage:WaitForChild("Getters")

-- Module Scripts
local Constants 				= require(ReplicatedStorage:WaitForChild("Constants"))
local getPlayerFromPlayerName 	= require(GettersFolder:WaitForChild("getPlayerFromPlayerName"))

function playerHasShop(playerName: string): boolean?
	local player = getPlayerFromPlayerName(playerName)
	if not player then
		return nil
	end
	return player:GetAttribute(Constants.PLAYER_CLAIM_ATTRIBUTES.SHOP_BOOL)
end

return playerHasShop