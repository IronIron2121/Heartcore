--!strict

--[[
	ActionsMenu - This function acts as a simple UI component, implementing an actions menu
	that is displayed when clicking an item the player is currently trying on.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local safeClamp = require(ReplicatedStorage.Utility.safeClamp)

export type Action = {
	name: string,
	callback: () -> (),
}

local actionsGuiTemplate = ReplicatedStorage.UI.Objects.ActionsGui
local actionButtonTemplate = ReplicatedStorage.UI.Objects.ActionButton

local function ActionsMenu(parent: GuiObject, actions: { Action }): ScreenGui
	local actionsGui = actionsGuiTemplate:Clone()

	for _, action in actions do
		local actionButton = actionButtonTemplate:Clone() :: TextButton
		actionButton.Text = action.name
		actionButton.Parent = actionsGui.ActionsFrame.ButtonsFrame

		actionButton.Activated:Connect(function()
			actionsGui:Destroy()
			action.callback()
		end)
	end

	local function updatePosition()
		local xPosition = parent.AbsolutePosition.X + parent.AbsoluteSize.X
		local yPosition = parent.AbsolutePosition.Y + parent.AbsoluteSize.Y * 0.5

		-- Clamp position
		local minXPos = 0
		local maxXPos = actionsGui.AbsoluteSize.X - actionsGui.ActionsFrame.AbsoluteSize.X
		xPosition = safeClamp(xPosition, minXPos, maxXPos)

		local minYPos = actionsGui.ActionsFrame.AbsoluteSize.Y * 0.5
		local maxYPos = actionsGui.AbsoluteSize.Y - actionsGui.ActionsFrame.AbsoluteSize.Y * 0.5
		yPosition = safeClamp(yPosition, minYPos, maxYPos)

		actionsGui.ActionsFrame.Position = UDim2.fromOffset(xPosition, yPosition)
	end

	local function onInputSinkActivated()
		actionsGui:Destroy()
	end

	actionsGui.InputSinkButton.Activated:Connect(onInputSinkActivated)
	actionsGui.ActionsFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)
	local positionChangedConnection = parent:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePosition)
	local sizeChangedConnection = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)

	actionsGui.Destroying:Once(function()
		positionChangedConnection:Disconnect()
		sizeChangedConnection:Disconnect()
	end)

	updatePosition()

	return actionsGui
end

return ActionsMenu
