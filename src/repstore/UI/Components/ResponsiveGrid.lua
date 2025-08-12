--!strict

--[[
	ResponsiveGrid - This function acts as a basic UI component, implementing a responsive grid
	which scales its cells to fit a minimum size based on the container size.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local responsiveGridTemplate = ReplicatedStorage.UI.Objects.ResponsiveGrid

local function ResponsiveGrid(minSize: Vector2, padding: number): ScrollingFrame
	local responsiveGrid = responsiveGridTemplate:Clone()
	responsiveGrid.UIGridLayout.CellPadding = UDim2.fromOffset(padding, padding)

	local function update()
		-- Calculate the total cell width including padding
		local cellWidth = minSize.X + padding
		local canvasWidth = responsiveGrid.AbsoluteSize.X - responsiveGrid.ScrollBarThickness
		-- Calculate how many cells will fit per line at minimum size
		local numCells = math.floor(canvasWidth / cellWidth)
		-- Calculate the scaling ratio required to fit the cells into the canvas
		local ratio = (canvasWidth - (numCells * padding)) / (numCells * minSize.X)

		responsiveGrid.UIGridLayout.CellSize = UDim2.fromOffset(minSize.X * ratio, minSize.Y * ratio)
	end

	responsiveGrid:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)

	update()

	return responsiveGrid
end

return ResponsiveGrid
