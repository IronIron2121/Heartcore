--!strict
-- BuyButton.lua

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

function BuyButton(
	scope: Fusion.Scope,
	props: {
		visible: UsedAs<boolean>?,
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		layoutOrder: UsedAs<number>?,
		anchorPoint: UsedAs<Vector2>?,
		text: UsedAs<string>?,
		onPurchaseCallback: (() -> ())?,
	}
): TextButton
	local isHovering = scope:Value(false)
	local isHeldDown = scope:Value(false)

	local BACKGROUND_COLOUR = UI_CONSTANTS.TASTEMAKER_PURPLE
	local backgroundColorSpring = scope:Spring(
		scope:Computed(function(use)
			if use(isHeldDown) then
				return BACKGROUND_COLOUR:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.55)
			elseif use(isHovering) then
				return BACKGROUND_COLOUR:Lerp(UI_CONSTANTS.COLOUR_BLACK, 0.20)
			else
				return BACKGROUND_COLOUR
			end
		end),
		20,
		1
	)

	local buyButton = scope:New "TextButton" {
		Name = "BuyButton",
		Visible = props.visible or true,
		Active = true,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		Size = props.size or UDim2.fromScale(0.8, 0.5),
		Text = props.text or "BUY",
		TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
		TextStrokeTransparency = 1,
		BackgroundColor3 = backgroundColorSpring,
		BackgroundTransparency = 0,
		LayoutOrder = props.layoutOrder or 1,
		TextScaled = true,
		TextWrapped = true,

		[OnEvent "Activated"] = function()
			if props.onPurchaseCallback then
				props.onPurchaseCallback()
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
				CornerRadius = UDim.new(0.4, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = UI_CONSTANTS.COLOUR_WHITE,
				Thickness = 2,
			}
		}
	} :: TextButton

	return buyButton
end

return BuyButton