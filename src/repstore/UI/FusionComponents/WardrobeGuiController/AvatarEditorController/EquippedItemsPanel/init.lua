--!strict

-- EquippedItemsPanel.lua

-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remotes
local PlayerRemovedItem = Remotes:WaitForChild("PlayerRemovedItem")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local peek = Fusion.peek
local Children = Fusion.Children

-- GUI Components
local EquippedItemButtons = require(script:WaitForChild("EquippedItemButtons"))

-- TODO -- Auto-scaling-canvas size and whatnot
function EquippedItemsPanel(
	scope: Fusion.Scope
)
	local loading = scope:Value(false)
	local buttonSize = scope:Value(UDim2.fromScale(0.8, 0.8))
	
	local equippedItemButtons = EquippedItemButtons(scope, buttonSize)

	local scrollFrame = scope:New "ScrollingFrame" {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),

		BackgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
		BackgroundColor3 = peek(loading) and UI_CONSTANTS.LOADING_GREY or UI_CONSTANTS.TASTEMAKER_PURPLE,

		-- Canvas
		CanvasSize = UDim2.fromScale(0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4,

		[Children] = {
			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				ItemLineAlignment = Enum.ItemLineAlignment.Center,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.Name
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0.2,0)
			},
			
			equippedItemButtons
		}
	} :: ScrollingFrame

	
	local EquippedItemsPanel = scope:New "Frame" {
			Size = UDim2.fromScale(1, 0.1),
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0),

		[Children] = {
			scrollFrame,
		}
	}
	
	return EquippedItemsPanel
end

return EquippedItemsPanel