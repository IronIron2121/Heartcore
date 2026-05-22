--!strict
-- ClientCameraController.lua
-- Saves the current camera state, locks to a given CFrame in Scriptable mode,
-- and restores the original state on deactivate.

local ClientCameraController = {}

local savedCameraType:   Enum.CameraType = Enum.CameraType.Custom
local savedCameraCFrame: CFrame          = CFrame.identity

function ClientCameraController.activate(cframe: CFrame)
	local camera = workspace.CurrentCamera
	savedCameraType   = camera.CameraType
	savedCameraCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame     = cframe
end

function ClientCameraController.deactivate()
	local camera = workspace.CurrentCamera
	camera.CameraType = savedCameraType
	if savedCameraType == Enum.CameraType.Scriptable then
		camera.CFrame = savedCameraCFrame
	end
end

return ClientCameraController
