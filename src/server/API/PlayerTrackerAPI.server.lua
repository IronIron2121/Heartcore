--!strict
--[[

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local getPlayerDetailsRemote = Remotes:WaitForChild("getPlayerDetailsRemote")

local Trackers = ReplicatedStorage:WaitForChild("Trackers")

local PlayerTracker = require(Trackers:WaitForChild("PlayerTracker"))
local Types = require(Utility:WaitForChild("Types"))

local function getPlayerDetails(player : Player) : Types.PlayerDetails
	return PlayerTracker.getPlayerDetails(player)
end

local function testReturn()
	return "test"
end

getPlayerDetailsRemote.OnServerInvoke = getPlayerDetails
]]