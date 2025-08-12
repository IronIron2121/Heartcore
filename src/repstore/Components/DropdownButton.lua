--!strict

--[[
	Dropdown - This function acts as a basic UI component, implementing a dropdown selection button.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DropdownDisplay = require(ReplicatedStorage.UI.Components.DropdownDisplay)

local player = Players.LocalPlayer :: Player
local playerGui = player.PlayerGui

local dropdownButtonTemplate = ReplicatedStorage.UI.Objects.DropdownButton

local function DropdownButton<T>(options: { T }, initialValue: T, updateFunction: (T) -> ()): GuiButton
	local dropdownButton = dropdownButtonTemplate:Clone()
	dropdownButton.ValueLabel.Text = tostring(initialValue)

	local function onOptionSelected(value: T)
		dropdownButton.ValueLabel.Text = tostring(value)
		updateFunction(value)
	end

	local function showDropdownOptions()
		local dropdownDisplay = DropdownDisplay(options, onOptionSelected, dropdownButton)
		dropdownDisplay.Parent = playerGui
	end

	dropdownButton.Activated:Connect(showDropdownOptions)

	return dropdownButton
end

return DropdownButton
