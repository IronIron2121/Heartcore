--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer     = game:GetService("StarterPlayer")

-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local ClientCameraController = require(script.Parent.Parent.Libraries.ClientCameraController)
local PlayerDisplayManager   = require(StarterPlayer.StarterPlayerScripts.GUI.PlayerDisplayManager)

-- Bindables / Values
local TransitionCompleted = Bindables:WaitForChild("TransitionCompleted") :: BindableEvent
local PodiumViewEndedBindable     = Bindables:WaitForChild("PodiumViewEndedBindable")     :: BindableEvent

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
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	ClientCameraController.activate(computeResultsCFrame())
	PlayerDisplayManager.HideAllDisplays()
end

local function deactivate()
	ClientCameraController.deactivate()
	PlayerDisplayManager.ShowAllDisplays()
	PodiumViewEndedBindable:Fire()
end

-- ─── Intermission flow ──────────────────────────────────────────────────────

TransitionCompleted.Event:Connect(function(stateName: string)
	if stateName == "Intermission" then
		activate()
		-- TODO: push XP results GUI here
		task.delay(5, deactivate)
	end
end)