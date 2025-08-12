--!strict

--[[
	RotateButton
	An invisible text button that tracks player mouse movement over the avatar preview
]]
-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

-- localPlayer
local localPlayer = Players.LocalPlayer
local playerMouse = localPlayer:GetMouse()

-- Fusion
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
type UsedAs<T> = Fusion.UsedAs<T>

-- Variables
local dt

local CONFIG = {
	-- Zoom settings
	MIN_ZOOM = 0.4,
	MAX_ZOOM = 2.0,
	ZOOM_STEP = 1.05,

	-- Rotation settings
	PITCH_LIMITS = {
		min = -45,
		max = 60
	},

	-- Sensitivity settings
	ROTATION_SENSITIVITY = {
		pitch_factor = 0.5 -- Pitch moves half as fast as yaw
	},

	-- RunService settings
	RENDER_STEP_PRIORITY = 2000,
	RENDER_STEP_NAME = "AvatarModelRotation",
	
	-- Appearance settings
	BACKGROUND_TRANSPARENCY = 1,
	TEXT = ""
	
}


function RotateButton(
	scope: Fusion.Scope,
	pitch: Fusion.Value<number>,
	yaw: Fusion.Value<number>,
	zoom: Fusion.Value<number>
)
	local isMouseDown = scope:Value(false)
	local isPinching = scope:Value(false)
	local baseZoom = 1
	
	local lastMouseX, lastMouseY = playerMouse.X, playerMouse.Y
	
	RunService:BindToRenderStep(CONFIG.RENDER_STEP_NAME, CONFIG.RENDER_STEP_PRIORITY, function(delta)
		dt = delta

		-- use TouchPan event for mobile devices
		if UserInputService.TouchEnabled then
			return
		end

		if peek(isMouseDown) then
			-- Get the change in Y and the change in X
			local dx, dy = playerMouse.X - lastMouseX, playerMouse.Y - lastMouseY

			local newYaw 	= peek(yaw) + dx
			local newPitch 	= peek(pitch) + (dy * CONFIG.ROTATION_SENSITIVITY.pitch_factor) 

			-- We can rotate 360 degrees horizontally, but limit the value of pitch to the top and bottom of the player model
			yaw:set(newYaw)
			pitch:set(math.clamp(
					newPitch,
					CONFIG.PITCH_LIMITS.min, 
					CONFIG.PITCH_LIMITS.max
				)
			)
		end

		lastMouseX = playerMouse.X
		lastMouseY = playerMouse.Y
	end)
	
	local function cleanUp()
		RunService:UnbindFromRenderStep(CONFIG.RENDER_STEP_NAME)
	end
	table.insert(scope, cleanUp)

	local rotateButton = scope:New "TextButton" {
		Name = "RotateButton",
		
		Text = CONFIG.TEXT,
		BackgroundTransparency = CONFIG.BACKGROUND_TRANSPARENCY,
		
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),

		[OnEvent("MouseButton1Down")] = function()
			isMouseDown:set(true)
		end,

		[OnEvent("MouseButton1Up")] = function()
			isMouseDown:set(false)
		end,

		[OnEvent("MouseLeave")] = function()
			isMouseDown:set(false)
		end,

		[OnEvent("MouseWheelForward")] = function()
			if zoom then
				warn("Zooming in!")
				zoom:set(math.clamp(peek(zoom) * CONFIG.ZOOM_STEP, 
					CONFIG.MIN_ZOOM, 
					CONFIG.MAX_ZOOM
					)
				)
			end
		end,  

		[OnEvent("MouseWheelBackward")] = function()
			if zoom then
				warn("Zooming out!")
				zoom:set(math.clamp(peek(zoom) / CONFIG.ZOOM_STEP, 
						CONFIG.MIN_ZOOM, 
						CONFIG.MAX_ZOOM
					)
				)
			end
		end,

		[OnEvent("TouchPan")] = function(_, _, vel)
			if peek(isPinching) then
				return
			end

			local dx, dy = vel.X*dt, vel.Y*dt

			yaw:set(peek(yaw) + dx)
			pitch:set(math.clamp(peek(pitch) + dy/CONFIG.ROTATION_SENSITIVITY.pitch_factor, CONFIG.PITCH_LIMITS.min, CONFIG.PITCH_LIMITS.max))
		end,

		[OnEvent("TouchPinch")] = function(_, scale, _, state)
			if zoom then
				if state == Enum.UserInputState.Begin then
					isMouseDown:set(false)
					isPinching:set(true)
					baseZoom = peek(zoom) or 1
				elseif state == Enum.UserInputState.Change then
					isMouseDown:set(false)
					zoom:set(math.clamp(baseZoom * scale, CONFIG.MIN_ZOOM, CONFIG.MAX_ZOOM))
				elseif state == Enum.UserInputState.End then
					baseZoom = nil
					isPinching:set(false)
				end
			end
		end
	} :: TextButton

	return rotateButton
end

return RotateButton
