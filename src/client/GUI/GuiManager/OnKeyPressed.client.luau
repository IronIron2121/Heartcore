--!strict

-- Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local GuiLibrary = Libraries:WaitForChild("GuiManager")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local CONFIGURATION_NAMES = require(GuiLibrary.CONFIGURATION_NAMES)
local MODAL_NAMES = require(GuiLibrary.MODAL_NAMES)
local GuiManager = require(GuiLibrary.GuiManager)

-- Fusion
local Fusion = require(Utility.Fusion)

--

local function OnKeyPressed(input: InputObject, gameProcessEvent: boolean)
    if input.KeyCode == Enum.KeyCode.J then
        GuiManager.PushCentreByName(MODAL_NAMES.Test)
    elseif input.KeyCode == Enum.KeyCode.N then
        GuiManager.PushCentreByName(MODAL_NAMES.Test2)
    elseif input.KeyCode == Enum.KeyCode.K then
        GuiManager.PopCentre()
    elseif input.KeyCode == Enum.KeyCode.V then
        GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.Configuration1)
    elseif input.KeyCode == Enum.KeyCode.B then
        GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.Configuration2)
    end
end 

--UserInputService.InputBegan:Connect(OnKeyPressed) 