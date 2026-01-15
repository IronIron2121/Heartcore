--!strict
-- Button.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS  = require(Utility.UI_CONSTANTS)
local Fusion = require(Utility.Fusion)

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek

function ImageButton(
	scope: Fusion.Scope,
	props: {
		name: UsedAs<string>?,
		active: UsedAs<boolean>?,
		visible: UsedAs<boolean>?,
		size: UsedAs<UDim2>?,
		image: UsedAs<string>?,
		position: UsedAs<UDim2>?, 
		layoutOrder: UsedAs<number>?,
		anchorPoint: UsedAs<Vector2>?,
		imageColor: UsedAs<Color3>?,
		cornerRadius: UsedAs<UDim>?,
		zIndex: UsedAs<number>?,
		onActivated: UsedAs<(() -> ())>?,
	}
): ImageButton
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)

	local imageColor = props.imageColor or UI_CONSTANTS.COLOUR_WHITE

	local imageColorSpring = scope:Spring(
		scope:Computed(function(use)
			local baseColor = imageColor

			if use(isHeldDown) then
				return baseColor:Lerp(UI_CONSTANTS.TASTEMAKER_PURPLE, 1)
			elseif use(isHovering) then
				return baseColor:Lerp(UI_CONSTANTS.TASTEMAKER_PURPLE, 0.20)
			else
				return baseColor
			end
		end),
		20,
		1
	)

	local imageButton = scope:New "ImageButton" {
		Name = props.name or "ImageButton",
		Active = props.active or true,
		Visible = props.visible or true,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		Size = props.size or UDim2.fromScale(0.8, 0.5),
		Image = props.image or nil,
		ImageColor3 = imageColorSpring,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 1,
		ZIndex = props.zIndex or 1,

		[OnEvent "Activated"] = function()
			if props.onActivated then
				peek(props.onActivated)()
			else
				warn("Button has no callback")
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
				CornerRadius = props.cornerRadius or UDim.new(0.5, 0)
			},

			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1,
				DominantAxis = 1,
			}
		}
	} :: ImageButton

	return imageButton
end

return ImageButton