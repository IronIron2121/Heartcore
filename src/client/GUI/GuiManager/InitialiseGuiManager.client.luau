--!strict

-- Catalog-only GUI bootstrap for a plain baseplate project.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local WardrobeGuiController = FusionComponents:WaitForChild("WardrobeGuiController")

local CatalogSearchController = require(WardrobeGuiController.CatalogSearchController)
local AvatarEditorController = require(WardrobeGuiController.AvatarEditorController)
local WardrobeContainer = require(WardrobeGuiController.WardrobeGui.WardrobeContainer)
local WardrobeGuiState = require(WardrobeGuiController.WardrobeGuiState)
local OpenWardrobeButton = require(FusionComponents.OpenWardrobeButton)
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local MODAL_NAMES = require(ReplicatedStorage.Libraries.GuiManager.MODAL_NAMES)
local Fusion = require(Utility:WaitForChild("Fusion"))

local Children = Fusion.Children

local localPlayer = Players.LocalPlayer
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

	hudScope:New "ScreenGui" {
		Name = "CatalogHud",
		DisplayOrder = 10,
		IgnoreGuiInset = true,
		Parent = localPlayer:WaitForChild("PlayerGui"),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		[Children] = {
			hudScope:New "Frame" {
				Name = "CatalogButtonContainer",
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.975, 0.5),
				Size = UDim2.fromOffset(96, 96),

				[Children] = {
					openWardrobeButton,
				},
			},
		},
	}
end

initialiseModals()
initialiseHud()
GuiManager.SetLoaded()
