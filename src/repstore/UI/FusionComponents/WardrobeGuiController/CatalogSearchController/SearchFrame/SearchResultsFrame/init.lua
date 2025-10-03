--!strict
-- SearchResultsFrame.lua
-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
-- Gui Components
local FusionItemTile = require(script:WaitForChild("FusionItemTile"))
-- Fusion
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local ForValues = Fusion.ForValues
local peek = Fusion.peek
-- Config
local CONFIG = {
	MIN_CELL_SIZE = Vector2.new(120, 150), -- Minimum size for each item tile
	CELL_PADDING_X = 10,
	CELL_PADDING_Y = 40 -- Padding between cells
}

function SearchResultsFrame(
	scope: Fusion.Scope,
	searchResults: Fusion.UsedAs<CatalogPages>?
): Frame

	local currentPage = scope:Computed(function(use)
		local results = use(searchResults)
		if results then
			return results:GetCurrentPage()
		else
			return {} -- Return empty table as fallback
		end
	end)

	-- Reactive values for responsive grid
	local cellSize = scope:Value(UDim2.fromOffset(CONFIG.MIN_CELL_SIZE.X, CONFIG.MIN_CELL_SIZE.Y))
	local gridLayout = scope:Value(nil)

	local searchResultsFrame = scope:New "ScrollingFrame" {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Name = "SearchResultsFrame",
		Size = UDim2.fromScale(1, 0.9),  
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 8,

		[Children] = {
			gridLayout:set(
				scope:New "UIGridLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					SortOrder = Enum.SortOrder.LayoutOrder,
					CellSize = cellSize,
					CellPadding = UDim2.fromOffset(CONFIG.CELL_PADDING_X, CONFIG.CELL_PADDING_Y)
				}
			),

			-- scope:New "UIPadding" {
			-- 	PaddingTop = UDim.new(0.01,0),
			-- 	PaddingBottom = UDim.new(0.01,0),
			-- 	PaddingRight = UDim.new(0.01,0),
			-- 	PaddingLeft = UDim.new(0.01,0),
			-- },

			scope:ForValues(currentPage, 
				function(use, scope, itemDetails)
					return FusionItemTile(scope, itemDetails)
				end)
		}

	} :: ScrollingFrame

	-- Responsive grid update function
	local function updateResponsiveGrid()
		local currentGridLayout = peek(gridLayout)
		if not currentGridLayout then return end

		-- Calculate the total cell width including padding
		local cellWidth = CONFIG.MIN_CELL_SIZE.X + CONFIG.CELL_PADDING_X
		local canvasWidth = searchResultsFrame.AbsoluteSize.X - searchResultsFrame.ScrollBarThickness

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
	searchResultsFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveGrid)

	-- Initial update
	task.defer(updateResponsiveGrid)

	return searchResultsFrame
end

return SearchResultsFrame