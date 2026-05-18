--!strict

-- Services
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
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
local WardrobeGuiState = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.WardrobeGuiState)
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
local VoteBarManager = require(FusionComponents.VoteBarManager) 
local ArenaTimerHud = require(FusionComponents.ArenaTimerHud)
local UI_CONSTANTS = require(Utility.UI_CONSTANTS)
local peek = require(FusionUtility.State.peek)
local ImageUris = require(DataTables.ImageUris) 
local FtuePop = require(ClientGUI.FtuePop)
local Fusion = require(FusionUtility)

local VotingStages = workspace:WaitForChild("VotingStages")
local lobby = workspace:WaitForChild("lobby")
local mainStage = workspace:WaitForChild("mainStage")


-- Remotes
local PlayerSubmittedOutfitRF = Remotes:WaitForChild("PlayerSubmittedOutfit") :: RemoteFunction

-- Fusion
local Children = Fusion.Children
local modalScope = Fusion:scoped() 

--

-- ### --- INITIAL LOADING SCREEN --- ### -- 
task.spawn(function()
    local initialLoadGui = modalScope:New "ScreenGui" {
        Parent = Players.LocalPlayer.PlayerGui,
        DisplayOrder = 9999,
        IgnoreGuiInset = true

    } :: ScreenGui

    local assetGroups = {
        VotingStages:GetDescendants(),
        lobby:GetDescendants(),
        mainStage:GetDescendants(),
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
    
    local openWardrobeButton = OpenWardrobeButton(hudScope, {
        onClick = function()
            if GuiManager.IsCentreActive() then
			    GuiManager.PopCentre()
            else
                -- We do this here rather than in the close button because otherwise players see the view change for a split second before the closing animation finishes
                WardrobeGuiState.ResetView()
                GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)
            end
        end
    })

    local submissionThemeBar = SubmissionThemeBar()

    local buttonsFrame = hudScope:New "Frame" {
        Size = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        BackgroundTransparency = 1,

        [Children] = {
            hudScope:New "UIListLayout" {
                Padding = UDim.new(0.15, 0),
                FillDirection = Enum.FillDirection.Vertical,
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
                        return ImageUris.Submit
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
                    if peek(GameStateValues.isDressing) then
                        if not peek(PlayerSubmissionState.cooldown) then
                            PlayerSubmittedOutfitRF:InvokeServer()
                        end
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
        }
    } :: Frame

    local voteBar = VoteBarManager.initialise()

    local GameLoopConfig = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.GameLoopConfig,
        topMiddle = { Object = submissionThemeBar, AlwaysOn = true },
        topRight = { Object = topRightContainer, AlwaysOn = true },
        middleRight = { Object = buttonsFrame, AlwaysOn = false },
        bottomLeft = nil,
        bottomMiddle = { Object = voteBar, AlwaysOn = false },
        bottomRight = { Object = GameOptionsFrame1, AlwaysOn = false },
    })

    local FtueConfig = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.FtueConfig,
        topMiddle = nil,
        topRight = nil,
        middleRight = nil,
        bottomLeft = nil,
        bottomMiddle = nil,
        bottomRight = nil,
    })

    local VotingHudConfig = GuiConfiguration.new({
        ConfigurationName = CONFIGURATION_NAMES.VotingConfig,
        topMiddle = { Object = ArenaTimerHud.frame, AlwaysOn = true },
        topRight = nil,
        middleRight = nil,
        middleLeft = nil,
        bottomLeft = nil,
        bottomMiddle = { Object = voteBar, AlwaysOn = true },
        bottomRight = nil,
    })

    GuiManager.RegisterConfiguration(GameLoopConfig)
    GuiManager.RegisterConfiguration(FtueConfig)
    GuiManager.RegisterConfiguration(VotingHudConfig)
    GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.FtueConfig)

    hudScope:Observer(GameStateValues.isVoting):onChange(function()
        if peek(GameStateValues.isVoting) then
            while GuiManager.IsCentreActive() do
                GuiManager.PopCentre()
            end
            GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.VotingConfig)
        else
            GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.GameLoopConfig)
        end
    end)
end

local function InitialiseModals()
    local dailyChallengeFrame = DailyChallengeFrame(modalScope)
    local wardrobeContainer, avatarContainer, catalogContainer = WardrobeContainer(modalScope)
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
    GuiManager.RegisterModal(MODAL_NAMES.PLAYER_INSPECT_GUI, playerClickFrame, onFrameOpened)
    GuiManager.RegisterModal(MODAL_NAMES.FTUE_GUI, ftuePop)

    local PlayerTriggeredCatalogConsole = Bindables:WaitForChild("PlayerTriggeredCatalogConsole")
    PlayerTriggeredCatalogConsole.Event:Connect(function(categoryName: string)
        print("Resetting GUI state")
        WardrobeGuiState.ResetView()
        print("Opening to top category")
        controllers["CatalogSearchController"]:OpenToTopCategory(categoryName)
        print("Pushing to modal manager top category")
        GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)
    end)
end

local function initialiseGuiManager()
    InitialiseModals()
    InitialiseHuds()
    GuiManager.SetLoaded()

    GuiManager.PushCentreByName(MODAL_NAMES.FTUE_GUI)
end

initialiseGuiManager()