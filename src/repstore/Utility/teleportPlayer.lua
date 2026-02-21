--!strict

--[[
	Teleports a player to a given part
]]


-- Local Constants
local TELEPORT_Y_OFFSET = 10

function teleportPlayer(player: Player, destination: BasePart, offSet: Vector3?)
	local playerCharacter = player.Character or player.CharacterAdded:Wait()
	local teleportOffset = Vector3.new(0, TELEPORT_Y_OFFSET, 0)
	if offSet then
		teleportOffset += offSet
	end

	playerCharacter:PivotTo(destination:GetPivot() + teleportOffset)
end

return teleportPlayer
