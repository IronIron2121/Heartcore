--!strict
-- InspectFrame.lua

-- Services
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Inspector = require(StarterPlayer.StarterPlayerScripts.Mannequins.Inspector)
local Constants = require(ReplicatedStorage.Constants)
local FusionItemTile = require(ReplicatedStorage.UI.FusionComponents.Widgets.FusionItemTile)
local peek = require(ReplicatedStorage.Utility.Fusion.State.peek)
local callWithRetry = require(ReplicatedStorage.Utility.callWithRetry)
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- Config
local CONFIG = {
	MIN_CELL_SIZE = Vector2.new(320, 350), -- Minimum size for each item tile
	CELL_PADDING_X = 10,
	CELL_PADDING_Y = 10 -- Padding between cells
}

local detailsCache = {}

function InspectFrame(
	scope: Fusion.Scope,
	props: {
		size: UsedAs<UDim2>?,
		position: UsedAs<UDim2>?,
		anchorPoint: UsedAs<Vector2>?,
		layoutOrder: UsedAs<number>?,
		backgroundTransparency: UsedAs<number>?,
		currentView: UsedAs<string>,
	}
): ScrollingFrame
	-- Reactive values for responsive grid
	local cellSize = scope:Value(UDim2.fromOffset(CONFIG.MIN_CELL_SIZE.X, CONFIG.MIN_CELL_SIZE.Y))
	local gridLayout = scope:New "UIGridLayout" {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		CellSize = cellSize,
		CellPadding = UDim2.fromOffset(CONFIG.CELL_PADDING_X, CONFIG.CELL_PADDING_Y)
	}

	local inspectedItems = Inspector.getInspectingItems()

	local inspectFrame = scope:New "ScrollingFrame" {
		Name = "InspectFrame",
		Visible = scope:Computed(function(use)
			return use(props.currentView) == Constants.WARDROBE_GUI_STATES.InspectFrame
		end),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.6,
		LayoutOrder = 2,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 8,

		[Children] = {
			gridLayout,
			scope:New "UIPadding" {
				PaddingTop = UDim.new(0,10),
				PaddingBottom = UDim.new(0,0),
				PaddingRight = UDim.new(0,0),
				PaddingLeft = UDim.new(0,0),
			},

			scope:New "UICorner" {
				CornerRadius = UDim.new(0.03,0)
			},

			scope:ForValues(inspectedItems, function(use, scope, item)
				local success
				local itemDetails = detailsCache[item.id]

				if not itemDetails then
					success, itemDetails = callWithRetry(
						function()
							return AvatarEditorService:GetItemDetailsAsync(item.id, (item.type == Enum.MarketplaceProductType.AvatarAsset and Enum.AvatarItemType.Asset or Enum.AvatarItemType.Bundle))
						end
					)
					if not success then 
						return
					else
						detailsCache[item.id] = itemDetails
					end
				end

				return FusionItemTile(scope, {itemDetails = itemDetails, layoutOrder = 1})
			end) 
		}
	} :: ScrollingFrame

	-- Responsive grid update function
	local function updateResponsiveGrid()
		local currentGridLayout = peek(gridLayout)
		if not currentGridLayout then return end

		-- Calculate the total cell width including padding
		local cellWidth = CONFIG.MIN_CELL_SIZE.X + CONFIG.CELL_PADDING_X
		local canvasWidth = inspectFrame.AbsoluteSize.X - inspectFrame.ScrollBarThickness

		-- Prevent division by zero
		if canvasWidth <= 0 then return end

		-- Calculate how many cells will fit per line at minimum size
		local numCells = math.max(1, math.floor(canvasWidth / cellWidth))

		-- Calculate the scaling ratio required to fit the cells into the canvas
		local availableWidth = canvasWidth - (numCells * CONFIG.CELL_PADDING_X)
		local ratio = availableWidth / (numCells * CONFIG.MIN_CELL_SIZE.X)

		-- Ensure ratio doesn't go below 1 (don't shrink below minimum size)
		ratio = math.max(1, ratio)

		-- Update cell size reactively
		local newCellSize = UDim2.fromOffset(
			CONFIG.MIN_CELL_SIZE.X * ratio, 
			CONFIG.MIN_CELL_SIZE.Y * ratio
		)
		cellSize:set(newCellSize)
	end

	-- Connect to size changes for responsive behavior
	inspectFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveGrid)

	-- Initial update
	task.defer(updateResponsiveGrid)

	return inspectFrame
end

return InspectFrame