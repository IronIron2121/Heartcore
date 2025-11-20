--!strict
-- OutfitTile.lua

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")


-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion = require(Utility:WaitForChild("Fusion"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))


-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek


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

	-- Create viewport camera
	local viewportCamera = scope:Value(nil)

	local isCurrentlyEquipping = scope:Value(false)
	
	local outfitTile = scope:New "Frame" {
		Name = "OutfitTile",
		Visible = props.visible or true,
		Size = props.size or UDim2.fromScale(0.25, 0.3),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = Color3.new(1, 1, 1),
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
				Size = UDim2.fromScale(0.8, 0.8),
				LayoutOrder = 1,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Ambient = Color3.new(1,1,1),
				LightColor = Color3.fromRGB(255, 249, 228),
				LightDirection = Vector3.new(1,1,1),

				[Children] = {
					scope:New "UICorner" {
						CornerRadius = UDim.new(0.05, 0)
					},

					scope:New "ImageButton" {
						Name = "CloseButton",
						Image = ImageUris["CloseButton"],
						AnchorPoint = Vector2.new(1, 0),
						Size = UDim2.fromScale(0.25, 0.25),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(1,0),
						
						[Children] = {
							scope:New "UIAspectRatioConstraint" {
								AspectRatio = 1
							}
						},
						
						[OnEvent "Activated"] = function()
							if props.onDelete then
								props.onDelete()
							end
							-- TODO: Refresh the GUI from here
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
					scope:New "TextButton" {
						Name = "WearButton",
						Size = UDim2.fromScale(0.4, 0.8),
						LayoutOrder = 1,
						BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
						Text = "Wear Outfit",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

						[OnEvent "Activated"] = function()
							if peek(isCurrentlyEquipping) then return end
							
							isCurrentlyEquipping:set(true)

							if props.onSelect then
								props.onSelect()
							end
							
							isCurrentlyEquipping:set(false)
						end,

						[Children] = {
							scope:New "UICorner" {
								CornerRadius = UDim.new(0.5, 0)
							},
						
							scope:New "UIPadding" {
								PaddingTop = UDim.new(0.05,0),
								PaddingBottom = UDim.new(0.05,0),
								PaddingLeft = UDim.new(0.05,0),
								PaddingRight = UDim.new(0.05,0),
							},
						},	
					},
					--[[
					-- Wear/Select Button
					scope:New "TextButton" {
						Name = "BuyButton",
						Size = UDim2.fromScale(0.4, 0.8),
						LayoutOrder = 2,
						BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
						Text = "Buy Outfit",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						Font = Enum.Font.Gotham,
						-- This functionality is not yet ready
						Visible = false,


						[OnEvent "Activated"] = function()
							PlayerPurchasedOutfit:FireServer(props.outfit.Id)
						end,

						[Children] = {
							scope:New "UICorner" {
								CornerRadius = UDim.new(0.1, 0)
							}
						}
					}
					]]
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

	return outfitTile
end

return OutfitTile