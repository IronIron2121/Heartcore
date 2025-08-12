--!strict

--[[
	This functions returns a mannequin instance from the workspace given an ID number
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Folders
local GettersFolder 	= ReplicatedStorage:WaitForChild("Getters")
local UtilityFolder 	= ReplicatedStorage:WaitForChild("Utility")
local Trackers 			= ReplicatedStorage:WaitForChild("Trackers")

local localPlayerDetails= require(Trackers:WaitForChild("localPlayerDetails"))
local Constants 		= require(ReplicatedStorage:WaitForChild("Constants"))
local Types 			= require(UtilityFolder:WaitForChild("Types"))

-- TODO: figure out a way to rationalise this and merge with serverside logic...
function getMannequinFromId(plr: Player, targetId: string): Types.spawnedMannequinType?
	local mannequins = CollectionService:GetTagged(Constants.MANNEQUIN_TAG)
	
	for _, mannequin in mannequins do
		local thisMannequinId = mannequin:GetAttribute(Constants.ITEM_ID_ATTRIBUTE)
		if thisMannequinId == targetId then
			return mannequin
		end
	end
	
	warn("Could not find mannequin with targetId " .. tostring(targetId))
	return nil
	
	--[[
	local plrShop = localPlayerDetails.getShopInstance()
	if not plrShop then return end
	
	for _, child in plrShop:GetDescendants() do
		if child:IsA("Model") and table.find(child:GetTags(), Constants.MANNEQUIN_TAG) then
			local thisMannequinId = child:GetAttribute(Constants.ITEM_ID_ATTRIBUTE)
			if thisMannequinId == targetId then
				return child
			end
		end
	end
	
	warn("Could not find mannequin with targetId " .. tostring(targetId))
	return nil
	]]
end

return getMannequinFromId
