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
				return UI_CONSTANTS.COLOUR_BLACK
			end
		end),
		20,
		1
	)	


	local equippedItemButtons = EquippedItemButtons(scope, {
		buttonSize = scope:Value(UDim2.fromScale(0.8, 0.8)),
		equipItemButtonsVisible = equipItemButtonsVisible
	})

	local scrollFrame = scope:New "ScrollingFrame" {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),

		BackgroundTransparency = 1,
		BackgroundColor3 = backgroundColourSpring,

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
			equippedItemButtons,
			scope:New "Frame" {
				Name = "rightBuffer",
				Size = UDim2.fromScale(0.03, 1),
				BackgroundTransparency = 1,
			}
		}
	} :: ScrollingFrame

	
	local EquippedItemsPanel = scope:New "Frame" {
			Size = UDim2.fromScale(1, 0.1),
			LayoutOrder = 2,
			BackgroundTransparency = backgroundTransparencySpring,
			BackgroundColor3 = backgroundColourSpring,
			AnchorPoint = Vector2.new(0, 0),

		[Children] = {
			scope:New "UICorner" {
				CornerRadius = UDim.new(0.2,0)
			},

			scope:New "UIPadding" {
				PaddingTop = UDim.new(0.01,0),
				PaddingBottom = UDim.new(0.01,0),
				PaddingLeft = UDim.new(0.01,0),
				PaddingRight = UDim.new(0,10),
			},
			scrollFrame,
		}
	}
	
	return EquippedItemsPanel
end

return EquippedItemsPanel