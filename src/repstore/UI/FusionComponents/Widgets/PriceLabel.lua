--!strict
-- BuyButton.lua

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")


-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))



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
)



local priceLabel = scope:New "Frame" {
	Name = "Container",
	AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
	Position = props.position or UDim2.fromScale(0.5, 0.5),
	Size = props.size or UDim2.fromScale(0.5, 0.3),
	BackgroundColor3 = Color3.new(1,1,1),
	BackgroundTransparency = 1,

	[Children] = {
		scope:New "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder
		},

		scope:New "TextLabel" {
			Name = "priceText",
			Visible = props.visible or true,
			AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
			Position = props.position or UDim2.fromScale(0.5, 0.5),
			Size = props.size or UDim2.fromScale(0.5,1),
			Text = `{props.text}` or "",
			TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
			BorderColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
			BorderSizePixel = 0,
			FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			TextStrokeTransparency = 1,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			TextScaled = false,
			TextSize = 20,
			TextWrapped = true,
			LayoutOrder = 2,
		},

		scope:New "ImageLabel" {
			Name = "RobuxIcon",
			Image = ImageUris.RobuxIcon,
			ImageColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
			BackgroundTransparency = 1,
			Visible = props.visible or true,
			Size =  UDim2.fromScale(1,1),
			LayoutOrder = 1,

			[Children] = {
                scope:New "UIAspectRatioConstraint" {
                	AspectRatio = 1,
                    DominantAxis = Enum.DominantAxis.Width,
                }
            }
		}
	}
}



	return priceLabel
end

return PriceLabel