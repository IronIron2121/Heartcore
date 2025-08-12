--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GettersFolder 	= ReplicatedStorage:WaitForChild("Getters")

local Constants 		= require(ReplicatedStorage.Constants)
local getHumanoidDescriptionFromPlayer = require(GettersFolder:WaitForChild("getHumanoidDescriptionFromPlayer"))

function getListOfAccessoryIdsFromPlayer(player: Player): {number}?
	-- Get player's humanoid description
	local humanoidDescription = getHumanoidDescriptionFromPlayer(player)
	if not humanoidDescription then return nil end
	
	local clothingTable = {}
	
	-- Go through every accessory slot in the description and convert them to numbers
	for _, attribute in pairs(Constants.HUMANOID_ACCESSORY_ATTRIBUTES) do
		local accessoryId = tonumber((humanoidDescription :: any)[attribute])
		-- Dynamic access is okay here as we know beforehand that these attributes are constant
		if accessoryId ~= 0 and accessoryId ~= nil then
			table.insert(clothingTable, accessoryId)
		else
			print("No dice in table! At, ", accessoryId)
		end
	end
	print("CLOTHING TABLE == ", clothingTable)
	
	return clothingTable
	
end

return getListOfAccessoryIdsFromPlayer
