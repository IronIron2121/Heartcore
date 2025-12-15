--!strict
-- CategoryButton.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

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
		isSelected: UsedAs<boolean>?
	}
): TextButton

	local isHovering = scope:Value(false)

	-- Visual feedback based on selection and hover state
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
				return UI_CONSTANTS.TASTEMAKER_PURPLE
			else
				return UI_CONSTANTS.COLOUR_WHITE
			end
		end)
	)
	
	local backgroundTransparencySpring = scope:Spring(
		scope:Computed(function(use)
			if use(props.isSelected) then
				return 0
			else
				return UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT
			end
		end)
	)

	local categoryButton = scope:New "TextButton" {
		Name = "CategoryButton",
		Size = props.size or UDim2.fromScale(0.15, 0.07),
		LayoutOrder = props.layoutOrder or 1,
		Text = props.text,
		TextColor3 = textColorSpring,
		TextScaled = true,
		FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
		BackgroundColor3 = backgroundColorSpring,
		BackgroundTransparency = backgroundTransparencySpring,
		BorderSizePixel = 0,

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
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.5, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(1, 1, 1),
				Thickness = 1,
			},

			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.1,0),
				PaddingBottom = UDim.new(0.1,0),
				PaddingLeft = UDim.new(0.1,0),
				PaddingRight = UDim.new(0.1,0)
			}
		}
	} :: TextButton

	return categoryButton
end

return CategoryButton