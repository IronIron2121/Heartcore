--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local GuiManangerLibrary = Libraries:WaitForChild("GuiManager")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")

-- Modules
local Types = require(Utility.Types)
local GuiConfiguration = require(GuiManangerLibrary.GuiConfiguration)
local MODAL_NAMES = require(GuiManangerLibrary.MODAL_NAMES)
local CONFIGURATION_NAMES = require(GuiManangerLibrary.CONFIGURATION_NAMES)
local GuiManager = require(GuiManangerLibrary.GuiManager)
local ExpHud = require(FusionComponents:WaitForChild("ExpHud"))
 
--

local function initialiseGuiManager()
    local expHud = ExpHud()
    local Configuration1 = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.Configuration1,
        bottomLeft = expHud
    })



    GuiManager.RegisterConfiguration(Configuration1)
    GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.Configuration1)

    --GuiManager.RegisterModal(MODAL_NAMES.Test, TestFrame)
    --GuiManager.RegisterModal(MODAL_NAMES.Test2, TestFrame2) 
end

initialiseGuiManager()