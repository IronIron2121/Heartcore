--!strict

--[[
	Teleports a player to a given part with a random X/Z scatter,
	so multiple players don't stack on the same point.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local teleportPlayer    = require(ReplicatedStorage:WaitForChild("Utility").teleportPlayer)

local RANDOM_SPREAD = 20  -- studs of scatter in each axis

local function randomTeleport(player: Player, destination: BasePart, offSet: Vector3?)
	local randOffset = Vector3.new(
		math.random(-RANDOM_SPREAD, RANDOM_SPREAD),
		0,
		math.random(-RANDOM_SPREAD, RANDOM_SPREAD)
	)
	teleportPlayer(player, destination, randOffset + (offSet or Vector3.zero))
end

return randomTeleport
