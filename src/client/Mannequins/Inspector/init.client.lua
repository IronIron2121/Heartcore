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
local LibrariesFolder = ReplicatedStorage:WaitForChild("Libraries")
local UIFolder = ReplicatedStorage:WaitForChild("UI")
local UIComponentsFolder = UIFolder:WaitForChild("Components")

-- Local references
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

-- GUI Elements
local shoppingGui = playerGui:WaitForChild("ShoppingGui")
local equipFrame = shoppingGui:WaitForChild("EquipFrame")
local inspectFrame = shoppingGui:WaitForChild("InspectFrame")
local topBar = inspectFrame:WaitForChild("TopBar")
local buyAllButton = topBar:WaitForChild("BuyAllButton")
local deleteButton = topBar:WaitForChild("DeleteButton")
local closeButton = topBar:WaitForChild("CloseButton")
local tryOnButton = topBar:WaitForChild("TryOnButton")
local editButton = topBar:WaitForChild("EditButton")
local addButton = topBar:WaitForChild("AddButton")
local itemsFrame: ScrollingFrame
local loadingDisplay: Frame

-- Modules
local stringOfNumbersToArray = require(UtiltyFolder:WaitForChild("stringOfNumbersToArray"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local ResponsiveGrid = require(UIComponentsFolder:WaitForChild("ResponsiveGrid"))
local LoadingDisplay = require(UIComponentsFolder:WaitForChild("LoadingDisplay"))
local CartButton = require(UIComponentsFolder:WaitForChild("CartButton"))
local ItemTile = require(UIComponentsFolder:WaitForChild("ItemTile"))
local ItemDetailsCache = require(LibrariesFolder:WaitForChild("ItemDetailsCache"))
local ModalManager = require(LibrariesFolder:WaitForChild("ModalManager"))
local TryOn = require(LibrariesFolder:WaitForChild("TryOn"))

-- Getters
local getMannequinFromId = require(GettersFolder:WaitForChild("getMannequinFromId"))
local getRecentMannequinId = require(GettersFolder:WaitForChild("getRecentMannequinId"))

-- Bindables
local shopClosedBindable = BindablesFolder:WaitForChild("PlayerClosedShopBindable")
local UpdateInspector = BindablesFolder:WaitForChild("UpdateInspector")
local PlayerInspectedMannequin = BindablesFolder:WaitForChild("PlayerInspectedMannequin") -- New bindable

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local bulkPurchaseRemote = remotes:WaitForChild("BulkPurchase")

-- State
local inspectingItems: { { id: number, type: Enum.MarketplaceProductType } } = {}
local isLoading = false
local isEditing = false

-- Function to make loading GUI visible when loading GUI elements
local function setLoading(loading: boolean)
	isLoading = loading
	loadingDisplay.Visible = loading
end

local function clearItemTiles()
	for _, child in itemsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function editButtonOwnershipToggle(mannequin)
	if mannequin:GetAttribute(Constants.SHOP_ITEM_OWNED_BY_ATTRIBUTE) == localPlayer.UserId then
		editButton.Visible = true
	else
		editButton.Visible = false
	end
end

local function makeItemsDeletable()
	for _, child in itemsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			local DeleteButton = child:WaitForChild("DeleteButton") :: TextButton
			local ButtonsFrame = child:WaitForChild("ButtonsFrame") :: Frame
			DeleteButton.Visible = true
			ButtonsFrame.Visible = false
		end
	end
end

local function makeItemsBuyable()
	for _, child in itemsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			local DeleteButton = child:WaitForChild("DeleteButton") :: TextButton
			local ButtonsFrame = child:WaitForChild("ButtonsFrame") :: Frame
			DeleteButton.Visible = false
			ButtonsFrame.Visible = true
		end
	end
end

local function inspectAsync(mannequin: Model, updating: boolean?)
	warn("Inspect async!")
	updating = updating or false

	-- Update the inspect frame's current mannequinID if it doesn't match the mannequin we're inspecting
	local mannequinId = mannequin:GetAttribute(Constants.ITEM_ID_ATTRIBUTE)
	local recentMannequinId = inspectFrame:GetAttribute(Constants.RECENT_MANNEQUIN_ATTRIBUTE)

	if mannequinId ~= recentMannequinId then
		inspectFrame:SetAttribute(Constants.RECENT_MANNEQUIN_ATTRIBUTE, mannequinId)
	end

	if not updating then
		-- Make the inspect frame visible
		ModalManager.push(inspectFrame)
	end

	editButtonOwnershipToggle(mannequin)

	if isLoading then
		return
	end

	local accessoryIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_ACCESSORY_IDS_ATTRIBUTE)
	local bundleIdsString = mannequin:GetAttribute(Constants.MANNEQUIN_BUNDLE_IDS_ATTRIBUTE)

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

	-- Clear all pre-existing item tiles
	clearItemTiles()
	setLoading(true)

	-- Create tiles for each of the accessories and bundles on the mannequin
	for _, accessoryId in accessoryIds do
		local assetDetails = ItemDetailsCache.getAssetDetailsAsync(accessoryId)
		if not assetDetails then
			continue
		end

		local itemTile = ItemTile(assetDetails, mannequinId, _, "Accessory")
		itemTile.Parent = itemsFrame
	end

	for _, bundleId in bundleIds do
		local bundleDetails = ItemDetailsCache.getBundleDetailsAsync(bundleId)
		if not bundleDetails then
			continue
		end
		local itemTile = ItemTile(bundleDetails, mannequinId, _, "Bundle")
		itemTile.Parent = itemsFrame
	end

	if isEditing then
		makeItemsDeletable()
	end

	setLoading(false)
end

local function updateInspector()
	local recentMannequinId = getRecentMannequinId()
	local mannequin = getMannequinFromId(localPlayer, recentMannequinId)
	if not mannequin then return end
	inspectAsync(mannequin, true)
end

-- Restores inspect GUI to its default state
local function resetInspectGui()
	topBar.BuyAllButton.Visible = true
	topBar.TryOnButton.Visible = true
	topBar.CartButton.Visible = true
	deleteButton.Visible = false
	addButton.Visible = false
	isEditing = false
end

-- Reset and close GUI
local function onCloseButtonActivated()
	ModalManager.pop(inspectFrame)
	resetInspectGui()
end

-- Try on all items in inspect frame
local function onTryOnButtonActivated()
	TryOn.setItemsAsync(inspectingItems)
end

-- Deletes a given mannequin from player store
local function onDeleteButtonActivated()
	onCloseButtonActivated()
end

local function onBuyAllButtonActivated()
	-- We need to convert the list of items to the format expected by MarketplaceService:PromptBulkPurchase()
	local bulkPurchaseItems = {}
	for _, item in inspectingItems do
		table.insert(bulkPurchaseItems, {
			Id = tostring(item.id),
			Type = item.type,
		})
	end

	-- Since PromptBulkPurchase can't be used on the client, we send the list of items to the server
	bulkPurchaseRemote:FireServer(bulkPurchaseItems)
end

local function onAddButtonActivated()
	ModalManager.push(equipFrame)
end

local function onEditButtonActivated()
	isEditing = not isEditing

	if isEditing then
		addButton.Visible = true
		topBar.DeleteButton.Visible = true
		topBar.BuyAllButton.Visible = false
		topBar.TryOnButton.Visible = false
		topBar.CartButton.Visible = false
		makeItemsDeletable()
	else
		addButton.Visible = false
		topBar.DeleteButton.Visible = false
		topBar.BuyAllButton.Visible = true
		topBar.TryOnButton.Visible = true
		topBar.CartButton.Visible = true
		makeItemsBuyable()
	end
end

-- Handler for when a mannequin inspection is requested
local function onMannequinInspectRequested(mannequin: Model)
	inspectAsync(mannequin)
end

local function initialise()
	-- initialise buttons
	deleteButton.Activated:Connect(onDeleteButtonActivated)
	buyAllButton.Activated:Connect(onBuyAllButtonActivated)
	closeButton.Activated:Connect(onCloseButtonActivated)
	tryOnButton.Activated:Connect(onTryOnButtonActivated)
	editButton.Activated:Connect(onEditButtonActivated)
	addButton.Activated:Connect(onAddButtonActivated)

	-- initialise items frame
	itemsFrame = ResponsiveGrid(Constants.ITEM_TILE_SIZE, Constants.ITEM_TILE_PADDING)
	itemsFrame.LayoutOrder = 1
	itemsFrame.Parent = inspectFrame

	-- initialise cart button
	local cartButton = CartButton()
	cartButton.LayoutOrder = 3
	cartButton.Parent = topBar

	-- initialise loading display
	loadingDisplay = LoadingDisplay()
	loadingDisplay.Parent = inspectFrame

	-- Connect to inspection requests from Mannequininitialiser
	PlayerInspectedMannequin.Event:Connect(onMannequinInspectRequested)

	-- Connect other bindables
	shopClosedBindable.Event:Connect(onCloseButtonActivated)
	UpdateInspector.Event:Connect(updateInspector)
end

initialise()