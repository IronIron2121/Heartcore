--!strict

-- Services
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerLibrary = Libraries:WaitForChild("GuiManager")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UI = ReplicatedStorage:WaitForChild("UI")

local WardrobeGuiController = UI.FusionComponents.WardrobeGuiController
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts
local DailyChallengeFolder = UI.FusionComponents.DailyChallengeGui
local FusionComponents = UI.FusionComponents
local FusionWidgets = FusionComponents.Widgets
local FusionUtility = Utility.Fusion
local GameState = StarterPlayerScripts.GameState
local ClientGUI = StarterPlayerScripts.GUI

-- Modules
local LoadingScreenManager = require(ReplicatedStorage.Libraries.LoadingScreenManager)
local OpenDailyChallengeGuiButton = require(FusionComponents:WaitForChild("OpenDailyChallengeGuiButton"))
local CatalogSearchController = require(WardrobeGuiController.CatalogSearchController)
local WardrobeContainer = require(WardrobeGuiController.WardrobeGui.WardrobeContainer)
local AvatarEditorController = require(WardrobeGuiController.AvatarEditorController)
local OutfitViewController = require(WardrobeGuiController.OutfitViewController)
local DailyChallengeFrame = require(DailyChallengeFolder.DailyChallengeFrame)
local CONFIGURATION_NAMES = require(GuiManagerLibrary.CONFIGURATION_NAMES)
local OpenWardrobeButton = require(FusionComponents.OpenWardrobeButton)
local PlayerSubmissionState = require(GameState.PlayerSubmissionState)
local GuiConfiguration = require(GuiManagerLibrary.GuiConfiguration)
local PlayerClickFrame = require(FusionComponents.PlayerClickFrame)
local SubmissionThemeBar = require(ClientGUI.SubmissionThemeBar)
local BaseImageButton = require(FusionWidgets.BaseImageButton)
local ExpHud = require(FusionComponents:WaitForChild("ExpHud"))
local GameStateValues = require(Libraries.GameStateValues)
local GuiManager = require(GuiManagerLibrary.GuiManager)
local MODAL_NAMES = require(GuiManagerLibrary.MODAL_NAMES)
local VotingFrame = require(FusionComponents.VotingFrame)
local UI_CONSTANTS = require(Utility.UI_CONSTANTS)
local peek = require(FusionUtility.State.peek)
local ImageUris = require(DataTables.ImageUris)
local FtuePop = require(ClientGUI.FtuePop)
local Fusion = require(FusionUtility)

local artistStores = workspace:WaitForChild("ArtistStores")
local lobbyRock = workspace:WaitForChild("lobbyRock")
local labelStores = workspace:WaitForChild("LabelStores")
local podium = workspace:WaitForChild("fitCheckPodium")
local layoutBlocks = workspace:WaitForChild("layoutBlocks")
local dailyWinners = workspace:WaitForChild("dailyWinners")
local curatedStores = workspace:WaitForChild("curatedStores")


-- Remotes
local PlayerSubmittedOutfitRF = Remotes:WaitForChild("PlayerSubmittedOutfit") :: RemoteFunction
local SetParticipatingRE = Remotes:WaitForChild("SetParticipating") :: RemoteEvent

-- Fusion
local Children = Fusion.Children
local modalScope = Fusion:scoped() 

--


task.spawn(function()
    local initialLoadGui = modalScope:New "ScreenGui" {
        Parent = Players.LocalPlayer.PlayerGui,
        DisplayOrder = 9999,
        IgnoreGuiInset = true

    } :: ScreenGui

    local assetGroups = {
        lobbyRock:GetDescendants(),
        podium:GetDescendants(),
        labelStores:GetDescendants(),
        artistStores:GetDescendants(),
        layoutBlocks:GetDescendants(),
        dailyWinners:GetDescendants(),
        curatedStores:GetDescendants()

    }
    local loadingText = modalScope:Value("...")
    local skipped = false

    LoadingScreenManager.show(initialLoadGui, {
        transparency = 0,
        text = loadingText,
        cornered = true,
        skippable = true,
        onSkipped = function()
            skipped = true
        end
    })

    while not game:IsLoaded() do
        task.wait(1)
    end

    for i, group in assetGroups do
        if skipped then break end
        loadingText:set(math.floor((i / #assetGroups) * 100) .. "%")
        ContentProvider:PreloadAsync(group)
    end

    LoadingScreenManager.hide(initialLoadGui)
    initialLoadGui:Destroy()
end)

local function InitialiseHuds()
    local hudScope = Fusion:scoped()
    local expHud = ExpHud(hudScope, { Size = UDim2.fromScale(1, 0.5) })
    local openDailyChallengesButton = OpenDailyChallengeGuiButton(hudScope)
    local openWardrobeButton = OpenWardrobeButton(hudScope)
    local submissionThemeBar = SubmissionThemeBar()

    local currentConfigurationName = GuiManager.GetCurrentConfigurationNameValue()

    local GameModeButton = BaseImageButton(hudScope, {
        name = "ChangeModeButton",
        layoutOrder = 2,
        size = UDim2.fromScale(0.6, 0.6),
        position = UDim2.fromScale(0.8,0),
        image = hudScope:Computed(function(use)
            local currentConfig = use(currentConfigurationName)
            if currentConfig == CONFIGURATION_NAMES.GameLoopConfig then
                return ImageUris.ExitFitCheck
            else
                return ImageUris.PlayFitCheck
            end
        end),

        onActivated = function()
            local currentConfig = peek(currentConfigurationName)
            if currentConfig == CONFIGURATION_NAMES.GameLoopConfig then
                GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.ShoppingConfig)
                SetParticipatingRE:FireServer(false)
            elseif currentConfig == CONFIGURATION_NAMES.ShoppingConfig then
                GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.GameLoopConfig)
                SetParticipatingRE:FireServer(true)
            end
        end,

        [Children] = {
            hudScope:New "UIAspectRatioConstraint" {
                AspectRatio = 1,
                AspectType = Enum.AspectType.FitWithinMaxSize,
                DominantAxis = Enum.DominantAxis.Width
            }
        }
    })

    local buttonsFrame = hudScope:New "Frame" {
        Size = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,

        [Children] = {
            hudScope:New "UIListLayout" {
                Padding = UDim.new(0.15, 0),
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
                Padding = UDim.new(0.15, 0),
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center
            },

            BaseImageButton(hudScope, {
                name = "GameStateButton",
                size = UDim2.fromScale(0.7,0.7),
                layoutOrder = 1,
                image = hudScope:Computed(function(use)
                    if use(GameStateValues.isDressing) then
                        if use(PlayerSubmissionState.cooldown) then
                            return ImageUris.Submit
                        else
                            return ImageUris.Submit
                        end
                    elseif use(GameStateValues.isVoting) then
                        return ImageUris.Vote
                    else
                        return ""
                    end
                end),
                imageColor3 = hudScope:Computed(function(use)  
                    return use(PlayerSubmissionState.cooldown) and UI_CONSTANTS.COLOUR_GREY or UI_CONSTANTS.COLOUR_WHITE
                end),
                backgroundColor = hudScope:Computed(function(use)
                    if use(GameStateValues.isIntermission) then
                        return UI_CONSTANTS.COLOUR_GREY
                    elseif use(GameStateValues.isDressing) and use(PlayerSubmissionState.cooldown) then
                        return UI_CONSTANTS.COLOUR_GREY
                    else
                        return UI_CONSTANTS.COLOUR_WHITE
                    end
                end),
                onActivated = function()
                    if (peek(GameStateValues.isDressing)) then
                        if not peek(PlayerSubmissionState.cooldown) then
                            PlayerSubmittedOutfitRF:InvokeServer()
                        end
                    elseif (peek(GameStateValues.isVoting)) then
                        GuiManager.PushCentreByName(MODAL_NAMES.VOTING_GUI)
                    end
                end,

                [Children] = {
                    hudScope:New "UIAspectRatioConstraint" {
                        AspectRatio = 1,
                        AspectType = Enum.AspectType.FitWithinMaxSize,
                        DominantAxis = Enum.DominantAxis.Width
                    }
                }
            })
        }
    } :: Frame

    local gameModeButtonFrame = hudScope:New "Frame" {
        Name = "GameModeButtonFrame",
        Size = UDim2.fromScale(1, 0.5),
        BackgroundTransparency = 1,

        [Children] = {
            GameModeButton
        }
    } :: Frame

    local topRightContainer = hudScope:New "Frame" {
        Name = "TopRightContainer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,

        [Children] = {
            hudScope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            },

            expHud,
            gameModeButtonFrame
        }
    } :: Frame

    local GameLoopConfig = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.GameLoopConfig,
        topMiddle = { Object = submissionThemeBar, AlwaysOn = true },
        topRight = { Object = topRightContainer, AlwaysOn = true },
        bottomLeft = nil,
        bottomMiddle = { Object = buttonsFrame, AlwaysOn = false },
        bottomRight = { Object = GameOptionsFrame1, AlwaysOn = false },
    })

    local ShoppingConfig = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.ShoppingConfig,
        topMiddle = nil,
        topRight = { Object = topRightContainer, AlwaysOn = false },
        bottomLeft = nil,
        bottomMiddle = { Object = buttonsFrame, AlwaysOn = false },
        bottomRight = nil,
    })

    local FtueConfig = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.FtueConfig,
        topMiddle = nil,
        topRight = nil,
        bottomLeft = nil,
        bottomMiddle = nil,
        bottomRight = nil,
    })

    GuiManager.RegisterConfiguration(GameLoopConfig)
    GuiManager.RegisterConfiguration(ShoppingConfig) 
    GuiManager.RegisterConfiguration(FtueConfig) 
    GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.FtueConfig)
end

local function InitialiseModals()
    local dailyChallengeFrame = DailyChallengeFrame(modalScope)
    local wardrobeContainer, avatarContainer, catalogContainer = WardrobeContainer(modalScope)
    local votingFrame, initialiseVoting = VotingFrame(modalScope)
    local playerClickFrame, onFrameOpened = PlayerClickFrame(modalScope)
    local ftuePop = FtuePop(modalScope)

    -- TODO: Find a more robust way of doing the below, this is vestigial code
	local controllers = {}
	controllers["CatalogSearchController"] = CatalogSearchController.new(catalogContainer, controllers, wardrobeContainer)
	controllers["AvatarEditorController"] = AvatarEditorController.new(avatarContainer, controllers) 
    controllers["VotingGuiController"] = nil
	controllers["OutfitViewController"] = OutfitViewController
	controllers["AvatarEditorController"]:Initialise()
	controllers["CatalogSearchController"]:Initialise()

    GuiManager.RegisterModal(MODAL_NAMES.DAILY_CHALLENGE_GUI, dailyChallengeFrame)
    GuiManager.RegisterModal(MODAL_NAMES.WARDROBE_GUI, wardrobeContainer) 
    GuiManager.RegisterModal(MODAL_NAMES.VOTING_GUI, votingFrame, initialiseVoting)
    GuiManager.RegisterModal(MODAL_NAMES.PLAYER_INSPECT_GUI, playerClickFrame, onFrameOpened)
    GuiManager.RegisterModal(MODAL_NAMES.FTUE_GUI, ftuePop)
end

local function initialiseGuiManager()
    InitialiseModals()
    InitialiseHuds()
    GuiManager.SetLoaded()

    GuiManager.PushCentreByName(MODAL_NAMES.FTUE_GUI)
end

initialiseGuiManager()