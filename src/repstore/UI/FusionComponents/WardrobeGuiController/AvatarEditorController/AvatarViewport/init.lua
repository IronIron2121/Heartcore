--!strict
-- AvatarViewport.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")


-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local ClientCustomisationService = require(StarterPlayer.StarterPlayerScripts.Clothing.ClientCustomisationService)
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local LoadingScreenManager = require(ReplicatedStorage.Libraries.LoadingScreenManager)
local Fusion = require(Utility:WaitForChild("Fusion"))
local ClientOutfitService = require(Utility:WaitForChild("ClientOutfitService"))

-- Fusion
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

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
	props: {
		model: UsedAs<Model>,
		currentView: Fusion.Value<string>,
		layoutOrder: UsedAs<number>,
		controllers: {any},
		outfitPurchasedCb: () -> (),
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
	
	local viewportOut: Fusion.Value<ViewportFrame?> = scope:Value(nil)
	
	local viewportBackground = scope:New "Frame" {
		Name = "ViewportContainer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.7, 1),
		LayoutOrder = props.layoutOrder or 2,
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,

		[Children] = {
			scope:New "ImageLabel" {
				Name = "viewportBackground",
				Size = UDim2.fromScale(1,1),
				Position = UDim2.fromScale(0, 0),
				AnchorPoint = Vector2.new(0, 0),
				Image = "rbxassetid://118393578077171",

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05)
					},
				},
			},

			viewportOut
		}
	} :: Frame

	local viewport = scope:New "ViewportFrame" {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Name = "AvatarViewport",
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
		ZIndex = 2,
		
		[Children] = {
			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(0.360784, 0.376471, 0.839216),
				Thickness = 2,
			},

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

			Button(scope, {
				name = "ResetButton",
				text = "Reset Outfit",
				size = UDim2.fromScale(0.4, 0.05),
				position = UDim2.fromScale(1,0),
				anchorPoint = Vector2.new(1,0),
				zIndex = 3,
				
				onActivated = function()
					if peek(viewportOut) ~= nil then
						LoadingScreenManager.show(peek(viewportBackground))
					end
					ClientCustomisationService.ResetPlayerOutfit(localPlayer)
					if peek(viewportOut) ~= nil then
						LoadingScreenManager.hide(peek(viewportBackground))
					end
				end, 
			}),

			Button(scope, {
				name = "OutfitsButtonFrame",
				text = "My Outfits",
				size = UDim2.fromScale(0.4, 0.05), 
				position = UDim2.fromScale(0,0),
				anchorPoint = Vector2.new(0,0),
				zIndex = 3,

				onActivated = function()
					props.currentView:set("Outfits")
				end,
			}),

			
			Button(scope, {
				text = "Buy outfit",
				size = UDim2.fromScale(0.4, 0.05),
				position = UDim2.fromScale(1,1),
				anchorPoint = Vector2.new(1,1),
				zIndex = 3,
				visible = true,
				
				onActivated = function()
					props.outfitPurchasedCb()
				end,
			}),
			
			Button(scope, {
				text = "Save Outfit",
				visible = true,
				size = UDim2.fromScale(0.4, 0.05),
				position = UDim2.fromScale(0,1),
				anchorPoint = Vector2.new(0,1),
				zIndex = 3,
				onActivated = function()
					GuiManager.PushNotificationCentre(
						"SaveOutfit", 
						"Are you sure you want to save this outfit?", 
						function()  
							ClientOutfitService.SaveCurrentPlayerOutfit()
							if not props.controllers.CatalogSearchController then
								return 
							end
							if not props.controllers.CatalogSearchController.updatePlayerOutfits then
								return 
							end
							props.controllers.CatalogSearchController.updatePlayerOutfits()
						end
					)
				end
			}),

			viewportCamera,

			rotateButton:set(
				RotateButton(scope, pitch, yaw, zoom) 
			),
		}
	} :: ViewportFrame
	
	viewportOut:set(viewport)

	viewport.CurrentCamera = peek(viewportCamera)

	-- Camera update function
	local function updateCameraPosition()
		local currentModel = peek(props.model)
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

return AvatarViewport