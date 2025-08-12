--!strict
-- AvatarViewport.lua

-- Services
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")


-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
-- TODO: get the actual URL, so to speak...this is hard to parse
local WardrobeGuiState = require(script.Parent.Parent.WardrobeGuiState)
local OutfitClientService = require(Utility:WaitForChild("OutfitClientService"))

-- Fusion
local peek = Fusion.peek
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

-- GUI Components
local RotateButton = require(script:WaitForChild("RotateButton"))
local Button = require(Widgets:WaitForChild("BaseButton"))

-- Local Player 
local localPlayer = Players.LocalPlayer

-- Config
local CONFIG = {
	MIN_ZOOM = 7,
	MAX_ZOOM = 11
}

function AvatarViewport(
	scope: Fusion.Scope,
	model: Fusion.UsedAs<Model> -- Changed from Value<Model> to UsedAs<Model>
): ViewportFrame
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
		local currentModel = use(model)
		return currentModel and currentModel:GetPivot() or CFrame.new()
	end)

	scope:Observer(pitchAndYaw):onChange(function()
		local currentModel = peek(model)
		local basePos = peek(baseCFrame)
		if not currentModel or not basePos then return end

		local pitchRad = math.rad(peek(pitch))
		local yawRad = math.rad(peek(yaw))
		-- Get the original position and rotate around it
		local rotatedCFrame = basePos * CFrame.Angles(-pitchRad, yawRad, 0)
		currentModel:PivotTo(rotatedCFrame)
	end)

	local viewportCamera = scope:Value(nil)
	local rotateButton = scope:Value(nil)
	
	local viewportOut = scope:Value(nil)

	local viewport = scope:New "ViewportFrame" {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Name = "AvatarViewport",
		Size = UDim2.fromScale(1, 0.85),  
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.new(0.65098, 0.65098, 0.65098),
		BorderSizePixel = 2,
		BorderColor3 = Color3.new(0.360784, 0.376471, 0.839216),
		LayoutOrder = 1,
		
		[Children] = {
			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(0.360784, 0.376471, 0.839216),
				Thickness = 2,
			},
			scope:New "WorldModel" {
				Name = "WorldModel",

				[Children] = scope:Computed(function(use)
					local currentModel = use(model) -- Use 'use' instead of peek to make it reactive
					return currentModel and {currentModel} or {}
				end)	
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0.05)
			},
			
			Button(scope, {
				text = scope:Computed(function(use)
					return use(WardrobeGuiState.currentView) == "Catalog" and "Save This Outfit" or "BUY outfit"
				end),
				
				size = UDim2.fromScale(0.3, 0.1),
				position = UDim2.fromScale(1,1),
				anchorPoint = Vector2.new(1,1),
				zIndex = 2,
				
				onActivated = function()
					if peek(WardrobeGuiState.currentView) == "Catalog" then
						OutfitClientService.SaveCurrentPlayerOutfit(localPlayer)
					else
						warn("Myeeee")
					end
				end,
			}),
			
			Button(scope, {
				text = "Alt 1",
				visible = scope:Computed(function(use)
					return use(WardrobeGuiState.currentView) ~= "Catalog"
				end),
				size = UDim2.fromScale(0.3, 0.1),
				position = UDim2.fromScale(0,1),
				anchorPoint = Vector2.new(0,1),
				zIndex = 2,
			}),

			viewportCamera:set(
				scope:New "Camera" {
					Name = "ViewportCamera",
				}
			),

			rotateButton:set(
				RotateButton(scope, pitch, yaw, zoom) 
			)
		}
	} :: ViewportFrame
	
	viewportOut:set(viewport)

	viewport.CurrentCamera = peek(viewportCamera)

	-- Camera update function
	local function updateCameraPosition()
		local currentModel = peek(model)
		local camera = peek(viewportCamera)
		if not currentModel or not camera then return end

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

	-- Update camera when model changes
	scope:Observer(model):onChange(updateCameraPosition)
	-- Update camera when zoom changes
	scope:Observer(zoomSpring):onChange(updateCameraPosition)
	-- Set up initial camera position
	task.defer(updateCameraPosition)

	return viewport
end

return AvatarViewport