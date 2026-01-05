--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local GuiManangerLibrary = Libraries:WaitForChild("GuiManager")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local DailyChallengeFolder = FusionComponents.DailyChallengeGui 


-- Modules
local Fusion = require(ReplicatedStorage.Utility.Fusion)
local GuiConfiguration = require(GuiManangerLibrary.GuiConfiguration)
local MODAL_NAMES = require(GuiManangerLibrary.MODAL_NAMES)
local CONFIGURATION_NAMES = require(GuiManangerLibrary.CONFIGURATION_NAMES)
local GuiManager = require(GuiManangerLibrary.GuiManager)
local ExpHud = require(FusionComponents:WaitForChild("ExpHud"))
local DailyChallengeFrame = require(DailyChallengeFolder.DailyChallengeFrame)
local OpenDailyChallengeGuiButton = require(FusionComponents:WaitForChild("OpenDailyChallengeGuiButton"))

-- Fusion
local Children = Fusion.Children
 
--

local function initialiseGuiManager()
    local hudScope = Fusion:scoped()
    local expHud = ExpHud(hudScope)
    local openDailyChallengesButton = OpenDailyChallengeGuiButton(hudScope)
    local buttonsFrame = hudScope:New "Frame" {
        Size = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,

        [Children] = {
            hudScope:New "UIListLayout" {
                Padding = UDim.new(0, 10),
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center
            },

            openDailyChallengesButton
        }
    } :: Frame

    local Configuration1 = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.Configuration1,
        bottomLeft = expHud,
        bottomMiddle = buttonsFrame
    })

    local modalScope = Fusion:scoped()
    local dailyChallengeFrame = DailyChallengeFrame(modalScope)

    GuiManager.RegisterConfiguration(Configuration1)
    GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.Configuration1)

    GuiManager.RegisterModal(MODAL_NAMES.DAILY_CHALLENGE_GUI, dailyChallengeFrame)
    --GuiManager.RegisterModal(MODAL_NAMES.Test2, TestFrame2) 
end

initialiseGuiManager()