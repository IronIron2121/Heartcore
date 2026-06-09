--!strict
-- ClientCameraController.lua
-- Saves the current camera state, locks to a given CFrame in Scriptable mode,
-- and restores the original state on deactivate.

local ClientCameraController = {}

local savedCameraType:   Enum.CameraType 	= Enum.CameraType.Custom
local savedCameraCFrame: CFrame         	= CFrame.identity
local defaultFov: number 					= 70

function ClientCameraController.activate(cframe: CFrame, fov: number?)
	local camera = workspace.CurrentCamera
	savedCameraType   = camera.CameraType
	savedCameraCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame     = cframe
	camera.FieldOfView = fov or defaultFov
end

function ClientCameraController.deactivate()
	print("Deactivating camera view")
	local camera = workspace.CurrentCamera
	camera.CameraType = savedCameraType
	if savedCameraType == Enum.CameraType.Scriptable then
		camera.CFrame = savedCameraCFrame
	end
	camera.FieldOfView = defaultFov
end

return ClientCameraController
