--!strict
-- OutfitVoteTile.lua

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Constants
local HOVER_COLOR = Color3.fromRGB(89, 247, 128)
local HOLD_COLOR = Color3.new(0.117647, 0.023529, 0.941176)

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek

function OutfitVoteTile(
	scope: Fusion.Scope,
	props: {
		name: UsedAs<string>?,
		visible: UsedAs<boolean>?,
		views: UsedAs<number>?,
		votes: UsedAs<number>?,
		IsSelected: UsedAs<boolean>?,
		userId: UsedAs<number>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?, 
		layoutOrder: UsedAs<number>?,  
		anchorPoint: UsedAs<Vector2>?,
		humanoidDescription: HumanoidDescription,
		strokeColor: UsedAs<Color3>?,
		strokeThickness: UsedAs<number>?,
		OnSelected: () -> (),
	}
): Frame
	local strokeColor = Color3.fromRGB(255, 255, 255) or UI_CONSTANTS.TASTEMAKER_PURPLE

	-- Create avatar model from HumanoidDescription
	local avatarModel = scope:Computed(function(use)
		if not props.humanoidDescription then 
            return nil 
        end

		local success, model = pcall(function()
			local model = Players:CreateHumanoidModelFromDescription(props.humanoidDescription, Enum.HumanoidRigType.R15)
			-- destroy animations
			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("BaseScript") then
					descendant:Destroy()
				end
			end
			return model 
		end)

		if success and model then
			-- Position the model at origin for viewport
			model:PivotTo(CFrame.new(0, -2.5, 0))
			return model
		else
			warn("Failed to create avatar model from HumanoidDescription")
			return nil
		end
	end)

	
	local isHovering = scope:Value(false)
	local isHeld = scope:Value(false)
	
	local strokeColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(isHeld) then
				return strokeColor:Lerp(HOLD_COLOR, 1)
			elseif use(props.IsSelected) then
				return strokeColor:Lerp(UI_CONSTANTS.TASTEMAKER_PURPLE, 1)
			elseif use(props.IsSelected) and use(isHovering) then
				return UI_CONSTANTS.TASTEMAKER_PURPLE:Lerp(HOVER_COLOR, 0.5)
			elseif use(isHovering) then
				return strokeColor:Lerp(HOVER_COLOR, 0.7)
			else
				return strokeColor
			end
		end),
		20,
		1	
	)

	-- Create viewport camera
	local viewportCamera = scope:Value(nil)

	local outfitVoteTile = scope:New "Frame" {
		Name = props.name,
		Visible = props.visible or true,
		Size = props.size or UDim2.fromScale(0.25, 0.3),
		Position = props.position,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = Color3.fromRGB(218, 214, 231),
		BackgroundTransparency = 0.1,

		[Children] = {
			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Padding = UDim.new(0, 5)
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0.05, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = strokeColorSpring,
				Thickness = 5,
			},

			-- Outfit thumbnail viewport
			scope:New "ViewportFrame" {
				Name = "OutfitViewport",
				Size = UDim2.fromScale(1, 1),
				LayoutOrder = 1,
				BackgroundColor3 = Color3.fromRGB(218, 214, 231),
				BackgroundTransparency = 0,
				BorderSizePixel = 5,
				Ambient = Color3.new(1,1,1),
				LightColor = Color3.fromRGB(255, 249, 228),
				LightDirection = Vector3.new(1,1,1),


				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05, 0)
					},

					

                    scope:New "ImageButton" {
                        Size = UDim2.fromScale(1, 1),
                        ImageTransparency = 1,
                        BackgroundTransparency = 1,


                        [OnEvent "Activated"] = function()
                            props.OnSelected()
                        end,

						[OnEvent "MouseButton1Down"] = function()
							isHeld:set(true)
						end,
						
						[OnEvent "MouseButton1Up"] = function()
							isHeld:set(false)
						end,
						
						[OnEvent "MouseEnter"] = function()
							isHovering:set(true)
						end,
						
						[OnEvent "MouseLeave"] = function()
							isHovering:set(false)
						end,

                    },

					scope:New "WorldModel" {
						Name = "WorldModel",

						[Children] = scope:Computed(function(use)
							local model = use(avatarModel)
							return model and {model} or {}
						end)
					},

					-- Set up viewport camera
					viewportCamera:set(
						scope:New "Camera" {
							Name = "ViewportCamera",
							CFrame = CFrame.new(Vector3.new(0, 0, 5), Vector3.new(0, 0, 0))
						}
					)
				},

				-- Set camera when viewport is created
				CurrentCamera = scope:Computed(function(use)
					return use(viewportCamera)
				end)
			},
		}
	} :: Frame

	-- Camera update function (copied from AvatarViewport)
	local function updateCameraPosition()
		local currentModel = Fusion.peek(avatarModel)
		local camera = Fusion.peek(viewportCamera)
		if not currentModel or not camera then return end

		local size = currentModel:GetExtentsSize()
		local biggestSize = math.max(size.X, size.Y)
		local FovInRadians = math.rad(camera.FieldOfView)
		local cameraDistance = (biggestSize / 2) / math.tan(FovInRadians / 2) * 1.05
		-- For outfit tiles, use a fixed zoom value instead of spring
		local zoomValue = 0.8 -- Fixed zoom for consistent tile appearance
		cameraDistance = math.clamp(cameraDistance, 7, 11) / zoomValue -- Using same min/max as CONFIG

		local modelCFrame = currentModel:GetPivot()
		local targetCFrame = (modelCFrame + (modelCFrame.LookVector * cameraDistance)) * CFrame.Angles(0, math.pi, 0)
		camera.CFrame = targetCFrame
	end

	-- Update camera when model changes
	scope:Observer(avatarModel):onChange(updateCameraPosition)
	-- Set up initial camera position
	task.defer(updateCameraPosition)

	return outfitVoteTile
end

return OutfitVoteTile