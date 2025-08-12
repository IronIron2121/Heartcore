--!strict
-- BuyButton.lua

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- TODO: Maybe this should have a parent class which try, remove and buy item can all inherit from
function PriceLabel(
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
	local priceLabel = scope:New "TextButton" {
		Name = "nameLabel",
		Visible = props.visible or true,
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.fromScale(0.5, 0.5),
		Size = props.size or UDim2.fromScale(0.8, 0.1),
		Text = `{props.text} ROBUX` or "",
		TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		BorderColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		BorderSizePixel = 0,
		FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextStrokeTransparency = 1,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 3,
		TextScaled = false,
		TextSize = 20,
		TextWrapped = true,

		[Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.2, 0)
			},

			scope:New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
				Thickness = 0,
			}
		}
	} :: TextButton

	return priceLabel
end

return PriceLabel