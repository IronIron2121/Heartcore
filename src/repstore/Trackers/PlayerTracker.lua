--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService 	= game:GetService("DataStoreService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(Utility:WaitForChild("Types"))

-- Constants
local RANDOM_ID_LOWER_BOUND : number = 1
local RANDOM_ID_UPPER_BOUND : number = 99999

--

local PlayerTracker = {}
local listOfPlayerDetails = {} :: {[number] : Types.PlayerDetails} 

function PlayerTracker.startTrackingPlayer(playerDetails : Types.PlayerDetails)
	listOfPlayerDetails[playerDetails.id] = playerDetails
end

function PlayerTracker.stopTrackingPlayer(playerDetails : Types.PlayerDetails)
	listOfPlayerDetails[playerDetails.id] = nil
end

function PlayerTracker.getPlayerDetails(player : Player) : Types.PlayerDetails?
	return listOfPlayerDetails[player.UserId]
end

--[[
function PlayerTracker.getPlayerShopData(player : Player) : {}
	return listOfPlayerDetails[player.UserId].getPlayerShopData()
end
]]	

return PlayerTracker