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
		OnSelected: () -> (),
		userId: UsedAs<number>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		anchorPoint: UsedAs<Vector2>?,
		humanoidDescription: HumanoidDescription,
		onSelect: () -> (),
	}
): Frame
	-- Create avatar model from HumanoidDescription
	local avatarModel = scope:Computed(function(use)
		if not props.humanoidDescription or not props.humanoidDescription then 
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
	local isHeldDown = scope:Value(false)

	local backgroundColourSpring = scope:Spring(
		scope:Computed(function(use)
			local backgroundColor = use(props.IsSelected) and UI_CONSTANTS.TASTEMAKER_PURPLE or UI_CONSTANTS.COLOUR_BLACK
			if use(isHeldDown) then
				return backgroundColor:Lerp(UI_CONSTANTS.COLOUR_WHITE, 0.8)
			elseif use(isHovering) then
				return backgroundColor:Lerp(UI_CONSTANTS.COLOUR_WHITE, 0.2)
			else
				return backgroundColor
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
		BackgroundColor3 = backgroundColourSpring,
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
				Color = Color3.fromRGB(200, 200, 200),
				Thickness = 1,
			},

			-- Outfit thumbnail viewport
			scope:New "ViewportFrame" {
				Name = "OutfitViewport",
				Size = UDim2.fromScale(1, 1),
				LayoutOrder = 1,
				BackgroundColor3 = backgroundColourSpring,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05, 0)
					},

                    scope:New "ImageButton" {
                        Size = UDim2.fromScale(1, 1),
                        ImageTransparency = 1,
                        BackgroundTransparency = 1,


                        [OnEvent "Activated"] = function()
                            props.onSelect()
                        end,

						[OnEvent "MouseButton1Down"] = function()
							isHeldDown:set(true)
						end,
						
						[OnEvent "MouseButton1Up"] = function()
							isHeldDown:set(false)
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