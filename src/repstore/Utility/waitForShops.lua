local WaitForShops = {}
local shopsFolder = workspace.PlayerShops
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Constants)

local function waitForShops()
	while #shopsFolder:GetChildren() < Constants.NUMBER_OF_SHOPS do
		RunService.Heartbeat:Wait()
	end
	return true
end

return waitForShops
