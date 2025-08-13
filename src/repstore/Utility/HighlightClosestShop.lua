--[[
	Highlights the shop closest to the player
]]

-- Services
local ReplicatedStorage 		= game:GetService("ReplicatedStorage")

-- Folders
local GettersFolder 			= ReplicatedStorage:WaitForChild("Getters")
local UtilityFolder				= ReplicatedStorage:WaitForChild("Utility")

-- Module Scripts
local findClosestShop			= require(GettersFolder:WaitForChild("findClosestShop"))
local makeArrowPointingAtPart 	= require(UtilityFolder:WaitForChild("makeArrowPointingAtPart"))
local HighlightPart 			= require(UtilityFolder:WaitForChild("HighlightPart"))

-- Objects
--local shopHighlight				= script.shopHighlight

-- Constants
local waitDuration 				= 5

-- Highlights the shop closest to a player
function HighlightClosestShop(player: Player)
	local closestShop = findClosestShop(player)
	if not closestShop then warn("No shop found!") return end
	
	--shopHighlight.Adornee = closestShop
	task.spawn(function()
		HighlightPart(closestShop)
	end)
	
	task.spawn(function()
		makeArrowPointingAtPart(player, closestShop)
	end)
	--shopHighlight.Adornee = nil
end

return HighlightClosestShop