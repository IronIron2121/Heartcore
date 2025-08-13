--!strict

--[[
	CameraOffset - This module implements a simple camera offset system, used to keep
	the character visible while the shop menu is open.
--]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera :: Camera

local BIND_NAME = "CameraOffsetBind"
local BIND_PRIORITY = Enum.RenderPriority.Camera.Value + 1

local enabled = false
local offset = 0

local function update()
	-- Calculate the offset distance in studs needed to keep the character at the specified
	-- offset in screen space.
	local zoomDistance = (camera.Focus.Position - camera.CFrame.Position).Magnitude
	local angle = math.rad(camera.MaxAxisFieldOfView * 0.5 * offset)
	local distance = math.tan(angle) * zoomDistance

	camera.CFrame *= CFrame.new(distance, 0, 0)
end

local CameraOffset = {}

function CameraOffset.enable(newOffset: number)
	if enabled then
		return
	end

	enabled = true
	offset = newOffset

	RunService:BindToRenderStep(BIND_NAME, BIND_PRIORITY, update)
end

function CameraOffset.disable()
	if not enabled then
		return
	end

	enabled = false

	RunService:UnbindFromRenderStep(BIND_NAME)
end

return CameraOffset
