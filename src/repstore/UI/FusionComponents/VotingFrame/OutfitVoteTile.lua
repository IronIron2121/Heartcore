--!strict
-- OutfitVoteTile.lua

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek

-- Constants
local DEFAULT_COLOR = Color3.fromRGB(218, 214, 231)
local WIN_COLOR = UI_CONSTANTS.TASTEMAKER_GREEN
local LOSE_COLOR = Color3.fromRGB(100, 100, 100) -- Grey
local HOVER_COLOR = UI_CONSTANTS.TASTEMAKER_GREEN
local COLOR_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

export type OutfitVoteTileControls = {
	triggerWin: () -> (),
	triggerLoss: () -> (),
}

local function OutfitVoteTile(
	scope: Fusion.Scope,
	props: {
		name: UsedAs<string>?,
		visible: UsedAs<boolean>?,
		position: UsedAs<UDim2>,
		size: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		humanoidDescription: HumanoidDescription,
		onActivated: () -> (),
	}
): (Frame, OutfitVoteTileControls)
	
	-- Internal state
	local backgroundColor = scope:Value(DEFAULT_COLOR)
	local backgroundColorTween = scope:Tween(backgroundColor, COLOR_TWEEN_INFO)
	
	local isHovering = scope:Value(false)
	local isHeld = scope:Value(false)
	local isInteractable = scope:Value(true)
	
	local strokeColor = scope:Spring(
		scope:Computed(function(use)
			if not use(isInteractable) then
				return LOSE_COLOR
			elseif use(isHeld) then
				return UI_CONSTANTS.TASTEMAKER_PURPLE
			elseif use(isHovering) then
				return HOVER_COLOR
			else
				return Color3.fromRGB(255, 255, 255)
			end
		end),
		20,
		1
	)

	-- Avatar model
	local avatarModel = scope:Computed(function(use)
		if not props.humanoidDescription then
			return nil
		end

		local success, model = pcall(function()
			local model = Players:CreateHumanoidModelFromDescription(props.humanoidDescription, Enum.HumanoidRigType.R15)
			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("BaseScript") then
					descendant:Destroy()
				end
			end
			return model
		end)

		if success and model then
			model:PivotTo(CFrame.new(0, -2.5, 0))
			return model
		else
			warn("Failed to create avatar model from HumanoidDescription")
			return nil
		end
	end)

	-- Viewport camera
	local viewportCamera = scope:Value(nil)

	local tile = scope:New "Frame" {
		Name = props.name or "OutfitVoteTile",
		Visible = props.visible or true,
		Size = props.size or UDim2.fromScale(0.25, 0.7),
		Position = props.position,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		BackgroundColor3 = backgroundColorTween,
		BackgroundTransparency = 0.1,

		[Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.05, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = strokeColor,
				Thickness = 5,
			},

			scope:New "ViewportFrame" {
				Name = "OutfitViewport",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = backgroundColorTween,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Ambient = Color3.new(1, 1, 1),
				LightColor = Color3.fromRGB(255, 249, 228),
				LightDirection = Vector3.new(1, 1, 1),

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05, 0)
					},

					scope:New "ImageButton" {
						Size = UDim2.fromScale(1, 1),
						ImageTransparency = 1,
						BackgroundTransparency = 1,

						[OnEvent "Activated"] = function()
							if peek(isInteractable) then
								props.onActivated()
							end
						end,

						[OnEvent "MouseButton1Down"] = function()
							if peek(isInteractable) then
								isHeld:set(true)
							end
						end,

						[OnEvent "MouseButton1Up"] = function()
							isHeld:set(false)
						end,

						[OnEvent "MouseEnter"] = function()
							isHovering:set(true)
						end,

						[OnEvent "MouseLeave"] = function()
							isHovering:set(false)
							isHeld:set(false)
						end,
					},

					scope:New "WorldModel" {
						Name = "WorldModel",

						[Children] = scope:Computed(function(use)
							local model = use(avatarModel)
							return model and { model } or {}
						end)
					},

					viewportCamera:set(
						scope:New "Camera" {
							Name = "ViewportCamera",
							CFrame = CFrame.new(Vector3.new(0, 0, 5), Vector3.new(0, 0, 0))
						}
					)
				},

				CurrentCamera = scope:Computed(function(use)
					return use(viewportCamera)
				end)
			},
		}
	} :: Frame

	-- Camera positioning
	local function updateCameraPosition()
		local currentModel = peek(avatarModel)
		local camera = peek(viewportCamera)
		if not currentModel or not camera then return end

		local size = currentModel:GetExtentsSize()
		local biggestSize = math.max(size.X, size.Y)
		local FovInRadians = math.rad(camera.FieldOfView)
		local cameraDistance = (biggestSize / 2) / math.tan(FovInRadians / 2) * 1.05
		local zoomValue = 0.8
		cameraDistance = math.clamp(cameraDistance, 7, 11) / zoomValue

		local modelCFrame = currentModel:GetPivot()
		local targetCFrame = (modelCFrame + (modelCFrame.LookVector * cameraDistance)) * CFrame.Angles(0, math.pi, 0)
		camera.CFrame = targetCFrame
	end

	scope:Observer(avatarModel):onChange(updateCameraPosition)
	task.defer(updateCameraPosition)

	-- Control functions
	local controls: OutfitVoteTileControls = {
		triggerWin = function()
			isInteractable:set(false)
			backgroundColor:set(WIN_COLOR)
			-- TODO: Play celebration animation on humanoid
			task.delay(0.5, function()
				backgroundColor:set(DEFAULT_COLOR)
				isInteractable:set(true)
			end)
		end,

		triggerLoss = function()
			isInteractable:set(false)
			backgroundColor:set(LOSE_COLOR)
			-- TODO: Play sad animation on humanoid
		end,
	}

	return tile, controls
end

return OutfitVoteTile