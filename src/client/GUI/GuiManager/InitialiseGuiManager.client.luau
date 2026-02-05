--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerLibrary = Libraries:WaitForChild("GuiManager")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI.FusionComponents
local DailyChallengeFolder = FusionComponents.DailyChallengeGui 
local WardrobeGuiController = FusionComponents.WardrobeGuiController

-- Modules
local SubmissionThemeBar = require(StarterPlayer.StarterPlayerScripts.GUI.SubmissionThemeBar)
local OpenWardrobeButton = require(ReplicatedStorage.UI.FusionComponents.OpenWardrobeButton)
local PlayerClickFrame = require(ReplicatedStorage.UI.FusionComponents.PlayerClickFrame)
local BaseButton = require(ReplicatedStorage.UI.FusionComponents.Widgets.BaseButton)
local AvatarEditorController = require(WardrobeGuiController.AvatarEditorController)
local CatalogSearchController = require(WardrobeGuiController.CatalogSearchController)
local OutfitViewController = require(WardrobeGuiController.OutfitViewController)
local WardrobeContainer = require(WardrobeGuiController.WardrobeGui.WardrobeContainer)
local Fusion = require(ReplicatedStorage.Utility.Fusion)
local Child = require(ReplicatedStorage.Utility.Fusion.Instances.Child)
local Children = require(ReplicatedStorage.Utility.Fusion.Instances.Children)
local GuiConfiguration = require(GuiManagerLibrary.GuiConfiguration)
local MODAL_NAMES = require(GuiManagerLibrary.MODAL_NAMES)
local CONFIGURATION_NAMES = require(GuiManagerLibrary.CONFIGURATION_NAMES)
local GuiManager = require(GuiManagerLibrary.GuiManager)
local ExpHud = require(FusionComponents:WaitForChild("ExpHud"))
local DailyChallengeFrame = require(DailyChallengeFolder.DailyChallengeFrame)
local OpenDailyChallengeGuiButton = require(FusionComponents:WaitForChild("OpenDailyChallengeGuiButton"))
local VotingFrame = require(FusionComponents.VotingFrame)

-- Fusion
local Children = Fusion.Children
 
--

local function InitialiseHuds()
    local hudScope = Fusion:scoped()
    local expHud = ExpHud(hudScope)
    local openDailyChallengesButton = OpenDailyChallengeGuiButton(hudScope)
    local openWardrobeButton = OpenWardrobeButton(hudScope)
    local submissionThemeBar = SubmissionThemeBar()
    local SubmitOutfitButton = BaseButton(hudScope, {
        onActivated = function()
            
        end
    })

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

    local GameOptionsFrame1 = hudScope:New "Frame" {
        Name = "GameOptionsFrame1",
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
        }
    } :: Frame

    local ShoppingConfig = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.ShoppingConfig,
        topMiddle = submissionThemeBar,
        topRight = expHud,
        bottomLeft = nil,
        bottomMiddle = buttonsFrame,
        bottomRight = nil
    })

    local GameLoopConfig = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.GameLoopConfig,
        topMiddle = nil,
        topRight = expHud,
        bottomLeft = nil,
        bottomMiddle = buttonsFrame,
        bottomRight = GameOptionsFrame1
    })

    GuiManager.RegisterConfiguration(ShoppingConfig) 
    GuiManager.RegisterConfiguration(GameLoopConfig)
    GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.GameLoopConfig)
end

local function InitialiseModals()
    local modalScope = Fusion:scoped() 
    local dailyChallengeFrame = DailyChallengeFrame(modalScope)
    local wardrobeContainer, avatarContainer, catalogContainer = WardrobeContainer(modalScope)
    local votingFrame, initialiseVoting = VotingFrame(modalScope)
    local playerClickFrame, onFrameOpened = PlayerClickFrame(modalScope)

    -- TODO: Find a more robust way of doing the below, this is vestigial code
	local controllers = {}
	controllers["CatalogSearchController"] = CatalogSearchController.new(catalogContainer, controllers) 
	controllers["AvatarEditorController"] = AvatarEditorController.new(avatarContainer, controllers) 
    controllers["VotingGuiController"] = nil
	controllers["OutfitViewController"] = OutfitViewController
	controllers["AvatarEditorController"]:Initialise()
	controllers["CatalogSearchController"]:Initialise()

    GuiManager.RegisterModal(MODAL_NAMES.DAILY_CHALLENGE_GUI, dailyChallengeFrame)
    GuiManager.RegisterModal(MODAL_NAMES.WARDROBE_GUI, wardrobeContainer) 
    GuiManager.RegisterModal(MODAL_NAMES.VOTING_GUI, votingFrame, initialiseVoting)
    GuiManager.RegisterModal(MODAL_NAMES.PLAYER_INSPECT_GUI, playerClickFrame, onFrameOpened)
end

local function initialiseGuiManager()
    InitialiseModals()
    InitialiseHuds()
    GuiManager.SetLoaded()
end

initialiseGuiManager()