--!strict

--[[
	This script handles the inspection GUI and all related functionality for viewing and managing
	items on mannequins.
--]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local GettersFolder = ReplicatedStorage:WaitForChild("Getters")
local UtiltyFolder = ReplicatedStorage:WaitForChild("Utility")
local BindablesFolder = ReplicatedStorage:WaitForChild("Bindables")
local UIFolder = ReplicatedStorage:WaitForChild("UI")
local UIComponentsFolder = UIFolder:WaitForChild("Components")

-- Local references
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

-- GUI Elements
local shoppingGui = playerGui:WaitForChild("ShoppingGui")
local itemsFrame: ScrollingFrame
local loadingDisplay: Frame

-- Modules
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local MODAL_NAMES = require(ReplicatedStorage.Libraries.GuiManager.MODAL_NAMES)
local WardrobeGuiState = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.WardrobeGuiState)
local stringOfNumbersToArray = require(UtiltyFolder:WaitForChild("stringOfNumbersToArray"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local ResponsiveGrid = require(UIComponentsFolder:WaitForChild("ResponsiveGrid"))
local LoadingDisplay = require(UIComponentsFolder:WaitForChild("LoadingDisplay"))
local CartButton = require(UIComponentsFolder:WaitForChild("CartButton"))

-- Getters
local getMannequinFromId = require(GettersFolder:WaitForChild("getMannequinFromId"))
local getRecentMannequinId = require(GettersFolder:WaitForChild("getRecentMannequinId"))

-- Bindables
local UpdateInspector = BindablesFolder:WaitForChild("UpdateInspector")
local PlayerInspectedMannequin = BindablesFolder:WaitForChild("PlayerInspectedMannequin") -- New bindable

-- Remotes

-- State
local inspectingItems: { { id: number, type: Enum.MarketplaceProductType } } = {}
local isLoading = false

--

local function inspectAsync(mannequin: Model, updating: boolean?)
	warn("Inspect async!")
	updating = updating or false

	if not updating then
		-- Make the inspect frame visible
		WardrobeGuiState.ChangeCurrentView("Mannequin")
		-- function here to activate the mannequin view...
		GuiManager.PushCentreByName(MODAL_NAMES.WARDROBE_GUI)
	end

	if isLoading then
		return
	end

	local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE) :: string
	local bundleIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE) :: string

	local accessoryIds = stringOfNumbersToArray(accessoryIdsString)
	local bundleIds = stringOfNumbersToArray(bundleIdsString)

	-- Wipe the inspected items list and then re-fill it with the items we're currently inspecting
	table.clear(inspectingItems)
	for _, accessoryId in accessoryIds do
		table.insert(inspectingItems, { id = accessoryId, type = Enum.MarketplaceProductType.AvatarAsset })
	end

	for _, bundleId in bundleIds do
		table.insert(inspectingItems, { id = bundleId, type = Enum.MarketplaceProductType.AvatarBundle })
	end
end