--!strict
-- CategoryButton.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

--Constants
local COLOUR_SELECTED = UI_CONSTANTS.COLOUR_LILAC
local DEFAULT_COLOUR = UI_CONSTANTS.TASTEMAKER_PURPLE
local HOVER_SCALE = 1.2 

-- Fusion
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
type UsedAs<T> = Fusion.UsedAs<T>

function CategoryButton(
	scope: Fusion.Scope,
	props: {
		onActivated: () -> (),
		text: UsedAs<string>,
		size: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		isSelected: UsedAs<boolean>?,
		textSize: UsedAs<number>?
	}
): TextButton

	local isHovering = scope:Value(false)

	local backgroundColorSpring = scope:Spring(scope:Computed(function(use)
		local selected = use(props.isSelected) or false
		local hovering = use(isHovering)

		if selected then
			return UI_CONSTANTS.COLOUR_WHITE
		elseif hovering then
			return UI_CONSTANTS.TASTEMAKER_PURPLE:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.25)
		else
			return UI_CONSTANTS.TASTEMAKER_PURPLE
		end
	end),
		20,
		1
	)

	
	local textColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(props.isSelected) then
				return COLOUR_SELECTED
			else
				return DEFAULT_COLOUR
			end
		end)
	)
	
	
	local sizeSpring = scope:Spring(
		scope:Computed(function(use)
			local hovering = use(isHovering)
			if hovering or use(props.isSelected) then
				return HOVER_SCALE
			else
				return 1
			end
		end),
		20, 
		1  
	)

	local categoryButton = scope:New "TextButton" {
		Name = "CategoryButton",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = props.size or UDim2.fromScale(0.15, 0.07),
		LayoutOrder = props.layoutOrder or 1,
		Text = props.text,
		TextColor3 = textColorSpring,
		TextScaled = false,
		FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
		BackgroundColor3 = backgroundColorSpring,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextSize = props.textSize or 20,
		TextXAlignment = Enum.TextXAlignment.Left,

		[OnEvent "Activated"] = function()
			if props.onActivated then
				props.onActivated()
				print(Fusion.peek(props.isSelected))
			end
		end, 

		[OnEvent "MouseEnter"] = function()
			isHovering:set(true)
		end,

		[OnEvent "MouseLeave"] = function()
			isHovering:set(false)
		end,

		[Children] = {
			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.1,0),
				PaddingBottom = UDim.new(0.1,0),
				PaddingLeft = UDim.new(0.05,0),
				PaddingRight = UDim.new(0.05,0)
			},

			scope:New "UIScale" {
				Scale = sizeSpring
			}
		}
	} :: TextButton

	return categoryButton
end

return CategoryButton