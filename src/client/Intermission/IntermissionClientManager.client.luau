--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Values = ReplicatedStorage:WaitForChild("Values")

-- Modules
local ClientCameraController = require(script.Parent.Parent.Libraries.ClientCameraController)

-- Values
local CurrentStateName = Values:WaitForChild("CurrentStateName") :: StringValue

-- World
local INTERMISSION_ZONE = workspace:WaitForChild("INTERMISSION_ZONE")
local winnersPodium     = INTERMISSION_ZONE:WaitForChild("WINNERS_PODIUM")
local winnersObs        = INTERMISSION_ZONE:WaitForChild("WINNER_OBSERVATION_POINT")

-- ─── Camera ─────────────────────────────────────────────────────────────────

local function computeResultsCFrame(): CFrame
	local camPos = winnersObs.Position + Vector3.new(0, 10, 12)
	local lookAt = winnersPodium.Position + Vector3.new(0, 10, 0)
	return CFrame.lookAt(camPos, lookAt)
end

local function activate()
	ClientCameraController.activate(computeResultsCFrame())
end

local function deactivate()
	ClientCameraController.deactivate()
end

-- ─── Intermission flow ──────────────────────────────────────────────────────

local function onIntermissionStarted()
	activate()
	-- TODO: push XP results GUI here
	task.delay(5, deactivate)
end

CurrentStateName.Changed:Connect(function(newState: string)
	if newState == "Intermission" then
		onIntermissionStarted()
	end
end)

-- Rejoin fallback
if CurrentStateName.Value == "Intermission" then
	task.delay(0.5, onIntermissionStarted)
end
