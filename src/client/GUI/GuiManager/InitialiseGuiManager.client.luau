--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local GuiManangerLibrary = Libraries:WaitForChild("GuiManager")

-- Modules
local Types = require(Utility.Types)
local GuiConfiguration = require(GuiManangerLibrary.GuiConfiguration)
local MODAL_NAMES = require(GuiManangerLibrary.MODAL_NAMES)
local CONFIGURATION_NAMES = require(GuiManangerLibrary.CONFIGURATION_NAMES)
local GuiManager = require(GuiManangerLibrary.GuiManager)

--

local function initialiseGuiManager()

    local TestFrame = Instance.new("Frame")
    TestFrame.Visible = false
    TestFrame.Size = UDim2.fromScale(0.5, 0.5)
    TestFrame.BackgroundColor3 = Color3.fromRGB(100,50,255)

    local TestFrame2 = Instance.new("Frame")
    TestFrame2.Visible = false
    TestFrame2.Size = UDim2.fromScale(0.7, 0.5)
    TestFrame2.BackgroundColor3 = Color3.fromRGB(50, 248, 255)

    local Configuration1 = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.Configuration1
    })
    local Configuration2 = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.Configuration2,
        color = Color3.new(100, 100, 0)
    })

    GuiManager.RegisterConfiguration(Configuration1)
    GuiManager.RegisterConfiguration(Configuration2)
    GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.Configuration1)

    GuiManager.RegisterModal(MODAL_NAMES.Test, TestFrame)
    GuiManager.RegisterModal(MODAL_NAMES.Test2, TestFrame2) 
end

initialiseGuiManager()