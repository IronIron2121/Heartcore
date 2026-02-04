--!strict
-- AvatarViewport.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local FusionComponents = UI:WaitForChild("FusionComponents")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI Components
local RotateButton = require(script:WaitForChild("RotateButton"))


-- Config
local CONFIG = {
	MIN_ZOOM = 7,
	MAX_ZOOM = 11
}

function PlayerInspectViewport(
	scope: Fusion.Scope,
	props: {
		model: UsedAs<Model>,
		layoutOrder: UsedAs<number>?,
		zIndex: UsedAs<number>?,
	}
): Frame
	-- Avatar manipulation variables
	local pitch = scope:Value(0)
	local yaw = scope:Value(0)
	local zoom = scope:Value(0.8)
	local zoomSpring = scope:Spring(zoom, 30)

	-- Detect when either value is changed
	local pitchAndYaw = scope:Computed(function(use, _)
		return {use(pitch), use(yaw)}
	end)

	local baseCFrame = scope:Computed(function(use)
		local currentModel = use(props.model)
		return currentModel and currentModel:GetPivot() or CFrame.new()
	end)

	local viewportCamera = scope:New "Camera" {
		Name = "ViewportCamera",
	} :: Camera

	local rotateButton = scope:Value(nil)
	
	local viewportOut = scope:Value(nil)

	local viewport = scope:New "ViewportFrame" {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Name = "PlayerInspectViewport",
		Size = UDim2.fromScale(1, 1),  
		LayoutOrder = props.layoutOrder or 2,
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 2,
		BorderColor3 = Color3.new(0.360784, 0.376471, 0.839216),
		Ambient = Color3.new(1,1,1),
		LightColor = Color3.fromRGB(255, 249, 228),
		LightDirection = Vector3.new(1,1,1),
		ZIndex = props.zIndex or 2,
		
		[Children] = {
			scope:New "WorldModel" {
				Name = "WorldModel",

				[Children] = scope:Computed(function(use)
					local currentModel = use(props.model) -- Use 'use' instead of peek to make it reactive
					return currentModel and {currentModel} or {}
				end)	
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0.05)
			},

			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.02,0),
				PaddingBottom = UDim.new(0.02,0),
				PaddingLeft = UDim.new(0.04,0),
				PaddingRight = UDim.new(0.04,0),
			},

			viewportCamera,

			rotateButton:set(
				RotateButton(scope, pitch, yaw, zoom) 
			),
		}
	} :: ViewportFrame
	
	local viewportBackground = scope:New "Frame" {
		Name = "ViewportContainer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		LayoutOrder = props.layoutOrder or 2,
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,

		[Children] = {
			scope:New "ImageLabel" {
				Name = "viewportBackground",
				Size = UDim2.fromScale(1,1),
				Position = UDim2.fromScale(0, 0),
				AnchorPoint = Vector2.new(0, 0),
				BackgroundTransparency = 1,
				ImageTransparency = 1,
				Image = "rbxassetid://118393578077171",

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05)
					},
				},
			},

			viewport
		}
	} :: Frame
	
	viewportOut:set(viewport)

	viewport.CurrentCamera = peek(viewportCamera)

	-- Camera update function
	local function updateCameraPosition()
		local currentModel = peek(props.model)
		warn(type(currentModel))
		warn(typeof(currentModel))
		local camera = peek(viewportCamera)
		if not currentModel or not camera then 
			return
		end

		local size = currentModel:GetExtentsSize()
		local biggestSize = math.max(size.X, size.Y)
		local FovInRadians = math.rad(camera.FieldOfView)
		local cameraDistance = (biggestSize / 2) / math.tan(FovInRadians / 2) * 1.05
		local zoomValue = peek(zoomSpring)
		cameraDistance = math.clamp(cameraDistance, CONFIG.MIN_ZOOM, CONFIG.MAX_ZOOM) / zoomValue

		local modelCFrame = peek(baseCFrame)
		local targetCFrame = (modelCFrame + (modelCFrame.LookVector * cameraDistance)) * CFrame.Angles(0, math.pi, 0)
		camera.CFrame = targetCFrame
	end

	local function updateModelRotation()
		local currentModel = peek(props.model)
		local basePos = peek(baseCFrame)
		if not currentModel or not basePos then return end

		local pitchRad = math.rad(peek(pitch))
		local yawRad = math.rad(peek(yaw))
		-- Get the original position and rotate around it
		local rotatedCFrame = basePos * CFrame.Angles(-pitchRad, yawRad, 0)
		currentModel:PivotTo(rotatedCFrame)
	end

	scope:Observer(pitchAndYaw):onChange(updateModelRotation)

	-- Update camera when model changes
	scope:Observer(props.model):onChange(function()
		updateCameraPosition()
		updateModelRotation()
	end)
	-- Update camera when zoom changes
	scope:Observer(zoomSpring):onChange(updateCameraPosition)
	-- Set up initial camera position
	task.defer(updateCameraPosition)

	return viewportBackground
end

return PlayerInspectViewport