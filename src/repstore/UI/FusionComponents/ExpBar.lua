--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))
local ExpConfig = require(Libraries:WaitForChild("ExpConfig"))

-- Fusion
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- Instances
local localPlayer = Players.LocalPlayer

-- Bridge leaderstats to Fusion Values so require() never blocks
local moduleScope = Fusion:scoped()
local expFusion   = Fusion.Value(moduleScope, 0)
local levelFusion = Fusion.Value(moduleScope, 1)

task.spawn(function()
    local ls        = localPlayer:WaitForChild("leaderstats")
    local expInst   = ls:WaitForChild("Exp")
    local levelInst = ls:WaitForChild("Level")

    expFusion:set(expInst.Value)
    levelFusion:set(levelInst.Value)

    expInst.Changed:Connect(function(v)   expFusion:set(v)   end)
    levelInst.Changed:Connect(function(v) levelFusion:set(v) end)
end)

function ExpBar(
	scope: Fusion.Scope,
	props: {
		name: UsedAs<string>?,
		active: UsedAs<boolean>?,
		visible: UsedAs<boolean>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		anchorPoint: UsedAs<Vector2>?,
		text: UsedAs<string>?,
		textScaled: UsedAs<boolean>?,
		backgroundColor: UsedAs<Color3>?,
		textColor: UsedAs<Color3>?,
		strokeColor: UsedAs<Color3>?,
		strokeThickness: UsedAs<number>?,
		cornerRadius: UsedAs<UDim>?,
		zIndex: UsedAs<number>?,
		onActivated: (() -> ())?,
	}
): Frame

	local MAX_BAR_SCALE = 0.75

	local expBarSize = scope:Tween(
		scope:Computed(function(use)
			local progress = ExpConfig.getProgress(use(expFusion), use(levelFusion))
			return UDim2.fromScale(progress * MAX_BAR_SCALE, 0.16)
		end),
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	)

	local frame = scope:New "Frame" {
		Name = "ExpBarContainer",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0),
		Size = UDim2.fromScale(0.5, 0.5),
		Position = UDim2.fromScale(0.35, 0),

		[Children] = {
			scope:New "ImageLabel" {
				Name = props.name or "ExpBar",
				Image = ImageUris.ExpBar,
				Visible = true,
				AnchorPoint = props.anchorPoint or Vector2.new(0, 0.5),
				Position = props.position or UDim2.fromScale(0, 0.5),
				Size = props.size or UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 2,

				[Children] = {
					scope:New "UIAspectRatioConstraint" {
						AspectRatio = 3,
					},

					scope:New "Frame" {
						Name = "ProgressFill",
						AnchorPoint = Vector2.new(0, 0.5),
						Size = expBarSize,
						Position = UDim2.fromScale(0.2, 0.47),
						BackgroundColor3 = Color3.new(1, 1, 1),
						ZIndex = 1,

						[Children] = {
							scope:New "UIGradient" {
								Color = ColorSequence.new(
									Color3.fromRGB(24, 107, 79),
									Color3.fromRGB(130, 194, 144)
								),
							},

							scope:New "UICorner" {
								CornerRadius = UDim.new(0.5, 0)
							},
						}
					}
				}
			},
		}
	} :: Frame

	return frame
end

return ExpBar