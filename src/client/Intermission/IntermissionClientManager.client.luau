--!strict

local INTERMISSION_ZONE = workspace:WaitForChild("INTERMISSION_ZONE")
local winnersPodium = INTERMISSION_ZONE:WaitForChild("WINNERS_PODIUM")
local winnersObs = INTERMISSION_ZONE:WaitForChild("WINNER_OBSERVATION_POINT")

-- ─── Camera ─────────────────────────────────────────────────────────────────
local savedCameraType:   Enum.CameraType = Enum.CameraType.Custom
local savedCameraCFrame: CFrame          = CFrame.identity

local function computeResultsCFrame(): CFrame
	if not INTERMISSION_ZONE then return CFrame.identity end

	-- Camera sits 8 studs above JudgePlatform, looking at chest height of the challengers
	local camPos = winnersPodium.Position + Vector3.new(0, 10, 12)
	local midpoint = winnersObs.Position
	local lookAt = midpoint + Vector3.new(0, 10, 0)

	return CFrame.lookAt(camPos, lookAt)
end

-- ─── Activate / deactivate ──────────────────────────────────────────────────
local function activate()
	local camera = workspace.CurrentCamera
	savedCameraType  = camera.CameraType
	savedCameraCFrame = camera.CFrame

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame     = computeResultsCFrame()
end

local function deactivate()
	local camera = workspace.CurrentCamera
	camera.CameraType = savedCameraType
	-- Only restore CFrame when switching back to Scriptable; Custom manages itself
	if savedCameraType == Enum.CameraType.Scriptable then
		camera.CFrame = savedCameraCFrame
	end
end