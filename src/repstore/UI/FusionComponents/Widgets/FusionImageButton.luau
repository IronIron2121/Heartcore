--!strict
-- Button.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS  = require(Utility.UI_CONSTANTS)
local Fusion = require(Utility.Fusion)

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
local peek = Fusion.peek

-- Constants
local COLOUR_ORANGE = Color3.new(0.901961, 0.380392, 0.078431)

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
		children: {any}
	}
): ImageButton
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)

	-- local imageColor = props.imageColor or UI_CONSTANTS.COLOUR_WHITE

	-- local imageColorSpring = scope:Spring(
	-- 	scope:Computed(function(use)
	-- 		local baseColor = imageColor

	-- 		if use(isHeldDown) then
	-- 			return baseColor:Lerp(COLOUR_ORANGE, 0.8)
	-- 		elseif use(isHovering) then
	-- 			return baseColor:Lerp(COLOUR_ORANGE, 0.25)
	-- 		else
	-- 			return baseColor
	-- 		end
	-- 	end),
	-- 	20,
	-- 	1
	-- )

	local imageButton = scope:New "ImageButton" {
		Name = props.name or "ImageButton",
		Active = props.active or true,
		Visible = props.visible or true,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		Size = props.size or UDim2.fromScale(0.8, 0.5),
		Image = props.image or nil,
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

		Rotation = scope:Spring(
					scope:Computed(function(use)
						if use(isHovering) then
							return 30
						else
							return 0
						end
					end),
					20
				),

		[Children] = {
			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1,
				DominantAxis = 1,
			},
			table.unpack(props.children or {})
		}
	} :: ImageButton

	return imageButton
end

return ImageButton