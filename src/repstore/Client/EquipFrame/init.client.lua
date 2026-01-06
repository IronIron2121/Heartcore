--[[
	This script contains all functionality for the GUI that allows user to equip accessories to mannequins
]]

--[[
-- Services
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Folders
local LibrariesFolder = ReplicatedStorage:WaitForChild("Libraries")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local UiFolder = ReplicatedStorage:WaitForChild("UI")
local ComponentsFolder = UiFolder:WaitForChild("Components")

-- Module Scripts
local RestrictedItems = require(LibrariesFolder:WaitForChild("RestrictedItems"))
local ModalManager = require(LibrariesFolder:WaitForChild("ModalManager"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

local disconnectAndClear = require(UtilityFolder:WaitForChild("disconnectAndClear"))
local Types = require(UtilityFolder:WaitForChild("Types"))

local ingestCatalogPage = require(script:WaitForChild("ingestCatalogPage")) 
local SortingFilters = require(script:WaitForChild("SortingFilters"))
local ItemFilters = require(script:WaitForChild("ItemFilters"))

local AccessoryTile = require(ComponentsFolder:WaitForChild("AccessoryTile"))
local DropdownButton = require(ComponentsFolder:WaitForChild("DropdownButton"))
local ResponsiveGrid = require(ComponentsFolder:WaitForChild("ResponsiveGrid"))
local LoadingDisplay = require(ComponentsFolder:WaitForChild("LoadingDisplay"))

-- GUI
local MannequinEquipTile = require(ComponentsFolder:WaitForChild("MannequinEquipTile"))

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI Elements
local playerGui = localPlayer.PlayerGui
local shoppingGui = playerGui:WaitForChild("ShoppingGui")
local equipFrame = shoppingGui:WaitForChild("EquipFrame")
local topBar = equipFrame:WaitForChild("TopBar")
local closeButton = topBar:WaitForChild("CloseButton")

local searchFrame = topBar:WaitForChild("SearchFrame")
local searchBox = searchFrame:WaitForChild("SearchBox")
local itemFilterDropdown: GuiButton
local sortingFilterDropdown: GuiButton
local equipsFrame: ScrollingFrame
local loadingDisplay: Frame

-- Variables
local searchParams = CatalogSearchParams.new()
local connections: { RBXScriptConnection } = {}
local isLoading = false



local function setLoading(loading: boolean)
	isLoading = loading
	loadingDisplay.Visible = loading
end

local function clearEquipTiles()
	for _, child in equipsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function onCloseButtonActivated()
	clearEquipTiles()
	ModalManager.pop(equipFrame)
end

-- Clear all item tiles and create new ones for the items in the specified page
local function displayPage(catalogPage: Types.CatalogPage)
	for _, itemDetails in catalogPage do
		local itemType = Enum.MarketplaceProductType[`Avatar{itemDetails.ItemType}`]
		if RestrictedItems.isRestricted(itemDetails.Id, itemType) then
			continue
		end

		local mannequinEquipTile = MannequinEquipTile(itemDetails)
		if not mannequinEquipTile then
			warn("Failed to create accessoryTile!")
			continue
		end
		mannequinEquipTile.Parent = equipsFrame
	end
end

local function shouldLoadNextPage(): boolean
	local bottomPosition = equipsFrame.AbsoluteWindowSize.Y * (2 - Constants.SCROLL_LOAD_FACTOR)
		+ equipsFrame.CanvasPosition.Y
	return bottomPosition >= equipsFrame.AbsoluteCanvasSize.Y
end

local function displayPagesAsync(catalogPages: CatalogPages)
	-- Clear the current item tiles and disconnect current connections
	clearEquipTiles()
	disconnectAndClear(connections)

	-- Scroll back to the top
	equipsFrame.CanvasPosition = Vector2.zero

	-- Load the first page and add it to the page cache
	local firstPage = catalogPages:GetCurrentPage() :: Types.CatalogPage

	local function loadNextPageAsync()
		-- Don't increment the page if we're currently loading another one
		if isLoading then
			return
		end

		if catalogPages.IsFinished then
			return
		end

		setLoading(true)
		catalogPages:AdvanceToNextPageAsync()
		setLoading(false)

		-- Add all item details in the page to the item details cache
		local page = catalogPages:GetCurrentPage()
		ingestCatalogPage(page)
		displayPage(page)
	end

	table.insert(
		connections,
		equipsFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if shouldLoadNextPage() then
				loadNextPageAsync()
			end
		end)
	)

	ingestCatalogPage(firstPage)
	displayPage(firstPage)

	while shouldLoadNextPage() and not catalogPages.IsFinished do
		loadNextPageAsync()
	end
end

local function searchAsync()
	-- Don't perform a search if we're currently searching/paging
	if isLoading then
		return
	end

	-- Perform the search using our search parameters
	setLoading(true)
	local catalogPages = AvatarEditorService:SearchCatalog(searchParams)
	setLoading(false)

	-- Display the returned pages
	displayPagesAsync(catalogPages)
end

local function onSearchBoxFocused()
	itemFilterDropdown.Visible = false
	sortingFilterDropdown.Visible = false
end

local function onSearchBoxFocusLost(enterPressed: boolean)
	itemFilterDropdown.Visible = true
	sortingFilterDropdown.Visible = true

	-- Update the search term, then perform a search if enter was pressed
	searchParams.SearchKeyword = searchBox.Text

	if enterPressed then
		searchAsync()
	end
end

local function onItemFilterChanged(filterName: string)
	-- Update the filtered asset/bundle types and then perform a search
	local filter = ItemFilters.filters[filterName]
	searchParams.AssetTypes = filter.assets
	searchParams.BundleTypes = filter.bundles

	searchAsync()
end

local function onSortingFilterChangedAsync(filterName: string)
	local filter = SortingFilters.filters[filterName]
	searchParams.SortType = filter

	searchAsync()
end

local function onInputBegan(inputObject: InputObject, processed: boolean)
	if processed then
		return
	end

	if inputObject.KeyCode == Settings.SHOP_GAMEPAD_KEY_CODE then
		onCloseButtonActivated()
	end
end

local function initialise()
	closeButton.Activated:Connect(onCloseButtonActivated)
	searchBox.Focused:Connect(onSearchBoxFocused)
	searchBox.FocusLost:Connect(onSearchBoxFocusLost)
	-- TODO: Use ContextActionService instead of UIS
	UserInputService.InputBegan:Connect(onInputBegan)

	-- initialise items frame
	equipsFrame = ResponsiveGrid(Constants.ITEM_TILE_SIZE, Constants.ITEM_TILE_PADDING)
	equipsFrame.LayoutOrder = 1
	equipsFrame.Parent = equipFrame

	-- initialise filters dropdown
	local initialItemFilter = ItemFilters.list[1]
	itemFilterDropdown = DropdownButton(ItemFilters.list, initialItemFilter, onItemFilterChanged)
	itemFilterDropdown.LayoutOrder = 1
	itemFilterDropdown.Parent = topBar

	-- initialise sorting dropdown
	local initialSortingFilter = SortingFilters.list[1]
	sortingFilterDropdown = DropdownButton(SortingFilters.list, initialSortingFilter, onSortingFilterChangedAsync)
	sortingFilterDropdown.LayoutOrder = 2
	sortingFilterDropdown.Parent = topBar

	-- initialise loading display
	loadingDisplay = LoadingDisplay()
	loadingDisplay.Parent = equipFrame	

	searchParams.Limit = Constants.PAGE_SIZE
	searchParams.IncludeOffSale = false
	searchParams.AssetTypes = ItemFilters.filters[initialItemFilter].assets
	searchParams.BundleTypes = ItemFilters.filters[initialItemFilter].bundles
	searchParams.SortType = SortingFilters.filters[initialSortingFilter]

	-- Do initial search
	--searchAsync()
end

initialise()


]]