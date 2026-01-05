--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local GuiManangerLibrary = Libraries:WaitForChild("GuiManager")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local DailyChallengeFolder = FusionComponents.DailyChallengeGui 


-- Modules
local SubmissionThemeBar = require(StarterPlayer.StarterPlayerScripts.GUI.SubmissionThemeBar)
local OpenWardrobeButton = require(ReplicatedStorage.UI.FusionComponents.OpenWardrobeButton)
local AvatarEditorController = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.AvatarEditorController)
local CatalogSearchController = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.CatalogSearchController)
local OutfitViewController = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.OutfitViewController)
local WardrobeContainer = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.WardrobeGui.WardrobeContainer)
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
    local openWardrobeButton = OpenWardrobeButton(hudScope)
    local submissionThemeBar = SubmissionThemeBar()

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

            openDailyChallengesButton,
            openWardrobeButton
        }
    } :: Frame

    local Configuration1 = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.Configuration1,
        bottomLeft = expHud,
        bottomMiddle = buttonsFrame,
        topMiddle = submissionThemeBar
    })

    local modalScope = Fusion:scoped() 
    local dailyChallengeFrame = DailyChallengeFrame(modalScope)
    local wardrobeContainer, avatarContainer, catalogContainer = WardrobeContainer(modalScope)

    -- TODO: Find a more robust way of doing the below, this is vestigial code
	local controllers = {}
	controllers["AvatarEditorController"] = AvatarEditorController.new(avatarContainer) 
	controllers["CatalogSearchController"] = CatalogSearchController.new(catalogContainer) 
	controllers["OutfitViewController"] = OutfitViewController
	controllers["AvatarEditorController"]:Initialise()
	controllers["CatalogSearchController"]:Initialise()

    GuiManager.RegisterConfiguration(Configuration1) 
    GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.Configuration1)

    GuiManager.RegisterModal(MODAL_NAMES.DAILY_CHALLENGE_GUI, dailyChallengeFrame)
    GuiManager.RegisterModal(MODAL_NAMES.WARDROBE_GUI, wardrobeContainer) 
end

initialiseGuiManager()