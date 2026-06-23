--!strict

-- Catalog-only GUI bootstrap for a plain baseplate project.

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer 	= game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local GuiManagerLibrary = Libraries:WaitForChild("GuiManager")
local WardrobeGuiController = FusionComponents:WaitForChild("WardrobeGuiController")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GUI = StarterPlayerScripts:WaitForChild("GUI")


-- Modules
local Constants = require(ReplicatedStorage.Constants)
local ImageUris = require(ReplicatedStorage.DataTables.ImageUris)
local FusionImageButton = require(ReplicatedStorage.UI.FusionComponents.FusionImageButton)
local CatalogSearchController = require(WardrobeGuiController.CatalogSearchController)
local AvatarEditorController = require(WardrobeGuiController.AvatarEditorController)
local WardrobeContainer = require(WardrobeGuiController.WardrobeGui.WardrobeContainer)
local WardrobeGuiState = require(WardrobeGuiController.WardrobeGuiState)
local OpenWardrobeButton = require(FusionComponents.OpenWardrobeButton)
local CONFIGURATION_NAMES = require(GuiManagerLibrary.CONFIGURATION_NAMES)
local GuiConfiguration = require(GuiManagerLibrary.GuiConfiguration)
local GuiManager = require(GuiManagerLibrary.GuiManager)
local MODAL_NAMES = require(GuiManagerLibrary.MODAL_NAMES)
local Fusion = require(Utility:WaitForChild("Fusion"))
local FtuePop = require(GUI.FtuePop) 

-- Remotes
local PlayerTeleportedToPlaceRE = Remotes.PlayerTeleportedToPlaceRE

local Children = Fusion.Children
local modalScope = Fusion:scoped()
local hudScope = Fusion:scoped()
local controllers: {[string]: any} = {}

local function openCatalog()
	if GuiManager.IsCentreActive() then
		GuiManager.PopCentre()
		return
	end

	WardrobeGuiState.ResetView()

	controllers.CatalogSearchController:OpenToTopCategory(nil)
	GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)
end

local function initialiseModals()
	local wardrobeContainer, avatarContainer, catalogContainer = WardrobeContainer(modalScope)
    local ftuePop = FtuePop(modalScope)


	controllers.CatalogSearchController = CatalogSearchController.new(catalogContainer, controllers, wardrobeContainer)
	controllers.AvatarEditorController = AvatarEditorController.new(avatarContainer, controllers)

	controllers.AvatarEditorController:Initialise()
	controllers.CatalogSearchController:Initialise()
 
	GuiManager.RegisterModal(MODAL_NAMES.WARDROBE_GUI, wardrobeContainer)
	GuiManager.RegisterModal(MODAL_NAMES.FTUE_GUI, ftuePop)
end

local function initialiseHud()
	local openWardrobeButton = OpenWardrobeButton(hudScope, {
		onClick = openCatalog,
	})

	local buttonsFrame = hudScope:New "Frame" {
		Name = "CatalogButtonsFrame",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(1, 1),

		[Children] = {
			hudScope:New "UIListLayout" {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0.15, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},

			openWardrobeButton,
		},
	}


	local homeButton = FusionImageButton(hudScope, {
        anchorPoint = Vector2.new(0.5, 0.5),
        position = UDim2.fromScale(0.5, 0.5),
        image = ImageUris.HomeButton,
        size = UDim2.fromScale(1, 0.5),
        backgroundTransparency = 1,
        onActivated = function()
            GuiManager.PushNotificationCentre(
                "MAIN_MENU",
                "Are you sure you want to return to the main menu?" , 
                function()
                    PlayerTeleportedToPlaceRE:FireServer(Constants.PLACE_IDS.MainMenu)     
                end
            )
        end,
        children = {
            hudScope:New "UIAspectRatioConstraint" {
                AspectRatio = 1,
                AspectType = Enum.AspectType.FitWithinMaxSize,
                DominantAxis = Enum.DominantAxis.Width
            }        
        }
	}) 

	local catalogConfig = GuiConfiguration.new({
		ConfigurationName = CONFIGURATION_NAMES.CatalogConfig,
		middleRight = {
			Object = buttonsFrame,
			AlwaysOn = false,
		},
		middleLeft = {
			Object = homeButton,
			AlwaysOn = false
		}
	})

	GuiManager.RegisterConfiguration(catalogConfig)
	GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.CatalogConfig)
	GuiManager.SetLoaded()
    GuiManager.PushCentreByName(MODAL_NAMES.FTUE_GUI)

end

initialiseModals()
initialiseHud()