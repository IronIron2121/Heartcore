--!strict

-- Catalog-only GUI bootstrap for a plain baseplate project.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local GuiManagerLibrary = Libraries:WaitForChild("GuiManager")
local WardrobeGuiController = FusionComponents:WaitForChild("WardrobeGuiController")

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

	controllers.CatalogSearchController = CatalogSearchController.new(catalogContainer, controllers, wardrobeContainer)
	controllers.AvatarEditorController = AvatarEditorController.new(avatarContainer, controllers)

	controllers.AvatarEditorController:Initialise()
	controllers.CatalogSearchController:Initialise()

	GuiManager.RegisterModal(MODAL_NAMES.WARDROBE_GUI, wardrobeContainer)
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

	local catalogConfig = GuiConfiguration.new({
		ConfigurationName = CONFIGURATION_NAMES.CatalogConfig,
		middleRight = {
			Object = buttonsFrame,
			AlwaysOn = false,
		},
	})

	GuiManager.RegisterConfiguration(catalogConfig)
	GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.CatalogConfig)
end

initialiseModals()
initialiseHud()
GuiManager.SetLoaded()
