--!strict

--[[
	Dropdown - This function acts as a basic UI component, implementing a dropdown selection display.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local connectTreeVisibilityChanged = require(ReplicatedStorage.Utility.connectTreeVisibilityChanged)
local safeClamp = require(ReplicatedStorage.Utility.safeClamp)

local dropdownGuiTemplate = ReplicatedStorage.UI.Objects.DropdownGui
local dropdownOptionTemplate = ReplicatedStorage.UI.Objects.DropdownOptionButton

local function DropdownDisplay<T>(options: { T }, updateFunction: (T) -> (), parent: GuiObject): ScreenGui
	-- In order to show the dropdown on top of everything, we clone a screengui to hold the dropdown UI.
	local dropdownDisplay = dropdownGuiTemplate:Clone() :: any

	local dropdownFrame = dropdownDisplay.DropdownFrame

	-- Add all of the options to the UI as buttons.
	for _, value in options do
		local optionButton = dropdownOptionTemplate:Clone()
		optionButton.Text = tostring(value)
		optionButton.Parent = dropdownFrame

		-- When the button is clicked, destroy the dropdown and call the update function.
		optionButton.Activated:Connect(function()
			dropdownDisplay:Destroy()
			updateFunction(value)
		end)
	end
	
	-----

	local function updateSizeAndPosition()
		local xPosition = parent.AbsolutePosition.X
		local yPosition = parent.AbsolutePosition.Y + parent.AbsoluteSize.Y

		-- Clamp xPosition and yPosition to the edges of the screen
		xPosition = safeClamp(xPosition, 0, dropdownDisplay.AbsoluteSize.X - dropdownFrame.AbsoluteSize.X)
		yPosition = safeClamp(yPosition, 0, dropdownDisplay.AbsoluteSize.Y - dropdownFrame.AbsoluteSize.Y)

		dropdownFrame.Position = UDim2.fromOffset(xPosition, yPosition)
		dropdownFrame.Size = UDim2.fromOffset(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
	end

	local function onTreeVisibilityChanged(isVisible: boolean)
		if not isVisible then
			dropdownDisplay:Destroy()
		end
	end

	-- A fullscreen button is used behind the dropdown to sink input, if it gets clicked the
	-- dropdown is destroyed.
	dropdownDisplay.InputSinkButton.Activated:Connect(function()
		dropdownDisplay:Destroy()
	end)

	dropdownFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSizeAndPosition)

	-- Update the position of the options menu if the button position changes (e.g. when the screen is resized)
	local positionChangedConnection = parent:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateSizeAndPosition)
	local sizeChangedConnection = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSizeAndPosition)

	local disconnectTreeVisibilityChanged = connectTreeVisibilityChanged(parent, onTreeVisibilityChanged)

	dropdownDisplay.Destroying:Once(function()
		positionChangedConnection:Disconnect()
		sizeChangedConnection:Disconnect()
		disconnectTreeVisibilityChanged()
	end)

	updateSizeAndPosition()

	return dropdownDisplay
end

return DropdownDisplay
