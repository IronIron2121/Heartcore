--!strict
-- EquippedItemsPanel.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local BaseButton = require(ReplicatedStorage.UI.FusionComponents.Widgets.BaseButton)
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

function EquippedItemsPanel(
	scope: Fusion.Scope,
	props: {
		layoutOrder: UsedAs<number>?,
		onAccessoriesRemovedCb: () -> ()
	}
): (Frame, ScrollingFrame)
	local equippedItemsContainer = scope:New "Frame" {
		Name = "EquippedItemsContainer",
		Size = UDim2.fromScale(0.3, 1),
		Position = UDim2.fromScale(0, 0),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundTransparency = 1,

		[Children] = {
			scope:New "Frame" {
				Size = UDim2.fromScale(1, 0.1),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				ZIndex = 2,
				
				[Children] = {
					BaseButton(scope, {
						text = "Remove All Accessories",
						size = UDim2.fromScale(0.8, 0.8),
						onActivated = function()
							props.onAccessoriesRemovedCb()
						end
					})
				}
			}
		}
	} :: Frame

	local equippedItemsPanel = scope:New "ScrollingFrame" {
		Name = "EquippedItemsPanel",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		AnchorPoint = Vector2.new(0, 0),
		CanvasSize = UDim2.fromScale(0, 0),
		LayoutOrder = props.layoutOrder or 1,
		BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		BackgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = equippedItemsContainer,
		ZIndex = 1,


		[Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.1, 0)
			},

			scope:New "UIListLayout" {
				Padding = UDim.new(0, 10),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.Name,
				ItemLineAlignment = Enum.ItemLineAlignment.End,
			},

			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.02, 0),
				PaddingBottom = UDim.new(0.02, 0),
				PaddingLeft = UDim.new(0.02, 0),
				PaddingRight = UDim.new(0.02, 0)
			}
		}
	} :: ScrollingFrame

	return equippedItemsContainer, equippedItemsPanel
end

return EquippedItemsPanel