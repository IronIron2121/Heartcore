--!strict
-- Button.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- Constants
local COLOUR_ORANGE = Color3.new(0.447059, 0.447059, 0.447059)
local COLOUR_GREY 	= Color3.new(1, 1, 1)
local BG_FADE_SPEED = 20

function ImageButton(
	scope: Fusion.Scope,
	props: {
		name: UsedAs<string>?,
        image: UsedAs<string>?,
		active: UsedAs<boolean>?,
		visible: UsedAs<boolean>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		anchorPoint: UsedAs<Vector2>?,
		text: UsedAs<string>?,
		textScaled: UsedAs<boolean>?,
		backgroundColor: UsedAs<Color3>?,
        imageColor3: UsedAs<Color3>?,
		textColor: UsedAs<Color3>?,
		strokeColor: UsedAs<Color3>?,
		strokeThickness: UsedAs<number>?,
		cornerRadius: UsedAs<UDim>?,
		zIndex: UsedAs<number>?,
		onActivated: (() -> ())?,
	}
): ImageButton
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)

	local imageColor = props.imageColor3 or UI_CONSTANTS.COLOUR_WHITE

	local imageColorSpring = scope:Spring(
		scope:Computed(function(use)
			local baseColor = use(imageColor)

			if use(isHeldDown) then
				return baseColor:Lerp(COLOUR_ORANGE, 0.8)
			elseif use(isHovering) then
				return baseColor:Lerp(COLOUR_ORANGE, 0.25)
			else
				return baseColor
			end
		end),
		20,
		1
	)

	local button = scope:New "ImageButton" {
		Name = props.name or "ImageButton",
        Image = props.image,
		Active = props.active or true,
		Visible = props.visible or true,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		Size = props.size or UDim2.fromScale(0.5, 0.5),
		ImageColor3 = props.imageColor3 or imageColorSpring,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 1,
		ZIndex = props.zIndex or 1,

		[OnEvent "Activated"] = function()
			if props.onActivated then
				props.onActivated()
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
			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1
			}
		}

	} :: ImageButton

	return button
end

return ImageButton