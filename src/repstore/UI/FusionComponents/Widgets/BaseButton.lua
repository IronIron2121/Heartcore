--!strict
-- Button.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

function Button(
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
): TextButton
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)

	local backgroundColor = props.backgroundColor or UI_CONSTANTS.COLOUR_WHITE

	local backgroundColorSpring = scope:Spring(
		scope:Computed(function(use)
			local baseColor = backgroundColor

			if use(isHeldDown) then
				return baseColor:Lerp(Color3.fromRGB(89, 247, 128), 1)
			elseif use(isHovering) then
				return baseColor:Lerp(Color3.fromRGB(89, 247, 128), 0.20)
			else
				return baseColor
			end
		end),
		20,
		1
	)

	local button = scope:New "TextButton" {
		Name = props.name or "Button",
		Active = props.active or true,
		Visible = props.visible or true,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		Size = props.size or UDim2.fromScale(0.8, 0.5),
		Text = props.text or "BUTTON",
		TextColor3 = props.textColor or UI_CONSTANTS.TASTEMAKER_PURPLE,
		TextStrokeTransparency = 1,
		BackgroundColor3 = backgroundColorSpring,
		BackgroundTransparency = 0,
		LayoutOrder = props.layoutOrder or 1,
		TextScaled = props.textScaled or true,
		TextWrapped = true,
		ZIndex = props.zIndex or 1,
		FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),

		[OnEvent "Activated"] = function()
			if props.onActivated then
				print("activating in button")
				props.onActivated()
			else
				warn("No activated function!")
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
			isHeldDown:set(false)
		end,

		[Children] = {
			scope:New "UICorner" {
				CornerRadius = props.cornerRadius or UDim.new(0.4, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = props.strokeColor or UI_CONSTANTS.TASTEMAKER_PURPLE,
				Thickness = props.strokeThickness or 3,
			},

			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.1,0),
				PaddingBottom = UDim.new(0.1,0),
				PaddingLeft = UDim.new(0.1,0),
				PaddingRight = UDim.new(0.1,0)
			}
		}
	} :: TextButton

	return button
end

return Button