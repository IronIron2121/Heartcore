--!strict
-- OutfitTile.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players 			= game:GetService("Players")

-- Folders
local DataTables 		= ReplicatedStorage:WaitForChild("DataTables")
local Utility 			= ReplicatedStorage:WaitForChild("Utility")
local UI 				= ReplicatedStorage:WaitForChild("UI")
local FusionComponents 	= UI:WaitForChild("FusionComponents")
local Widgets 			= FusionComponents:WaitForChild("Widgets")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local BaseButton = require(Widgets:WaitForChild("BaseButton"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek

-- Constants
local COLOUR_ORANGE 			= Color3.new(0.901961, 0.380392, 0.078431)
local COLOUR_GREY 				= Color3.new(1, 1, 1)
local BG_FADE_SPEED 			= 20

--

function OutfitTile(
	scope: Fusion.Scope,
	props: {
		visible: UsedAs<boolean>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		anchorPoint: UsedAs<Vector2>?,
		text: UsedAs<string>?,
		humanoidDescription: HumanoidDescription,
		outfit: Fusion.UsedAs<{}>?,
		onSelect: () -> (),
		onDelete: () -> ()?,
		onClick: () -> (),
	}
): Frame
	warn("making outfit tile for, ", props.humanoidDescription)
	-- Create avatar model from HumanoidDescription
	local avatarModel = scope:Computed(function(use)
		if not props.humanoidDescription then return nil end

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

		-- State management
	local Toggled = scope:Value(false)
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)

	local COLOUR_BG_TOGGLED = COLOUR_ORANGE
	local COLOUR_BG_NOT_TOGGLED = COLOUR_GREY

	local isClicked = scope:Computed(function(use, _)
		return use(Toggled) == true
	end)

	-- Create viewport camera
	local viewportCamera = scope:Value(nil)

	local isCurrentlyEquipping = scope:Value(false)
	
	local outfitTile = scope:New "Frame" {
		Name = "Container",
		Visible = props.visible or true,
		Size = props.size or UDim2.fromScale(0.3, 0.3),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,

		[Children] = {
			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1
			},

			scope:New "ImageButton" {
				Name = "RemoveButton",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.9, 0.01),
				Size = UDim2.fromScale(0.2, 0.2),
				ZIndex = 3,
				BackgroundTransparency = 1,
				Image = ImageUris.TrashButton,
				Active = true,

				[OnEvent "Activated"] = function()
					if props.onClick ~= nil then
						props.onClick()
					end
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

				ImageColor3 = scope:Spring(
					scope:Computed(function(use)
						local baseColor = use(isClicked) and COLOUR_BG_TOGGLED or COLOUR_BG_NOT_TOGGLED
						
						if use(isHeldDown) then
							return baseColor:Lerp(COLOUR_ORANGE, 0.8)
						elseif use(isHovering) then
							return baseColor:Lerp(COLOUR_ORANGE, 0.25)
						else 
							return baseColor
						end
					end),
					BG_FADE_SPEED
				), 
				
				[OnEvent "Activated"] = function()
					if props.onDelete then
						props.onDelete()
					end
					-- TODO: Refresh the GUI from here
				end,
			},

			scope:New "Frame" {
				Name = "OutfitTile",
				Visible = props.visible or true,
				Size = props.size or UDim2.fromScale(1,1),
				Position = props.position,
				AnchorPoint = props.anchorPoint,
				LayoutOrder = props.layoutOrder,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1,

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

					-- Outfit thumbnail viewport
					scope:New "ViewportFrame" {
						Name = "OutfitViewport",
						Size = UDim2.fromScale(0.8, 0.8),
						LayoutOrder = 1,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.4,
						BorderSizePixel = 0,
						Ambient = Color3.new(1,1,1),
						LightColor = Color3.fromRGB(255, 249, 228),
						LightDirection = Vector3.new(1,1,1),

						[Children] = {
							scope:New "UICorner" {
								CornerRadius = UDim.new(0.05, 0)
							},

							scope:New "UIStroke" {
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
								Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
								Thickness = 3,
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

					-- Button frame
					scope:New "Frame" {
						Name = "ButtonsFrame",
						Size = UDim2.fromScale(1, 0.2),
						LayoutOrder = 2,
						BackgroundTransparency = 1,

						[Children] = {
							scope:New "UIListLayout" {
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								Padding = UDim.new(0, 5)
							},

							-- Wear/Select Button
							BaseButton(scope, {
								name = "WearButton",
								size = UDim2.fromScale(0.6, 0.8),
								LayoutOrder = 1,
								text = "Wear Outfit",
								textScaled = true,

								onActivated = function()
									if peek(isCurrentlyEquipping) then return end
									
									isCurrentlyEquipping:set(true)

									if props.onSelect then
										props.onSelect()
									end
									
									isCurrentlyEquipping:set(false)
								end,
							}),
						},
					}
				}
			}
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
		
		-- Apply zoom factor
		local zoomValue = 0.8 
		cameraDistance = cameraDistance / zoomValue
		
		-- Clamp AFTER applying zoom
		cameraDistance = math.clamp(cameraDistance, 3, 7)

		local modelCFrame = currentModel:GetPivot()
		local targetCFrame = (modelCFrame + (modelCFrame.LookVector * cameraDistance)) * CFrame.Angles(0, math.pi, 0)
		camera.CFrame = targetCFrame
	end

	-- Update camera when model changes
	scope:Observer(avatarModel):onChange(updateCameraPosition)
	-- Set up initial camera position
	task.defer(updateCameraPosition)

	return outfitTile
end

return OutfitTile