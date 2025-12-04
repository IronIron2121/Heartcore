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
	scope: Fusion.Scope,
	props: {
		layoutOrder: number
	}
)
	local equipItemButtonsVisible = scope:Value(true)

	local backgroundTransparencySpring = scope:Spring(
		scope:Computed(function(use)
			if use(equipItemButtonsVisible) then
				return UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT
			else
				return 0
			end
		end),
		20,
		1
	)	

	local backgroundColourSpring = scope:Spring(
		scope:Computed(function(use)
			if use(equipItemButtonsVisible) then
				return UI_CONSTANTS.TASTEMAKER_PURPLE
			else
				return UI_CONSTANTS.COLOUR_WHITE
			end
		end),
		20,
		1
	)	


	local equippedItemButtons = EquippedItemButtons(scope, {
		buttonSize = scope:Value(UDim2.fromScale(0.7, 0.7)),
		equipItemButtonsVisible = equipItemButtonsVisible
	})

	local scrollFrame = scope:New "ScrollingFrame" {
		Name = "EquippedItemsScrollingFrame",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		LayoutOrder = props.layoutOrder or 1,

		BackgroundTransparency = 1,
		BackgroundColor3 = backgroundColourSpring,

		-- Canvas
		CanvasSize = UDim2.fromScale(0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageTransparency = 1,

		[Children] = {
			scope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				ItemLineAlignment = Enum.ItemLineAlignment.Center,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder
			},			

			equippedItemButtons,

			scope:New "Frame" {
				Name = "rightBuffer",
				Size = UDim2.fromScale(1, 0.03),
				BackgroundTransparency = 1,
				LayoutOrder = 999999
			}
		}
	} :: ScrollingFrame

	local equippedItemsPanel = scope:New "Frame" {
		Name = "EquippedItemsPanel",
		Size = UDim2.fromScale(0.3, 1),
		LayoutOrder = props.layoutOrder or 1,
		BackgroundTransparency = backgroundTransparencySpring,
		BackgroundColor3 = backgroundColourSpring,
		AnchorPoint = Vector2.new(0, 0),

		[Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.2,0)
			},

			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.02,0),
				PaddingBottom = UDim.new(0.02,0),
				PaddingLeft = UDim.new(0.03,0),
				PaddingRight = UDim.new(0.03,0), 
			},

			scrollFrame,
		}
	}
	
	return equippedItemsPanel
end

return EquippedItemsPanel 