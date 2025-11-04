--!strict

-- CatalogSearchController.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local AssetFilterCategories = require(DataTables:WaitForChild("AssetFilterCategories"))
local BundleFilterCategories = require(DataTables:WaitForChild("BundleFilterCategories"))
local WardrobeGuiState = require(script.Parent:WaitForChild("WardrobeGuiState"))
local FusionItemTile = require(Widgets:WaitForChild("FusionItemTile"))


-- Fusion Components
local Fusion = require(Utility:WaitForChild("Fusion"))
local peek = Fusion.peek

-- GUI Components
local CategoryFrame = require(script:WaitForChild("CategoryFrame"))
local OutfitsFrame = require(script:WaitForChild("OutfitsFrame"))
local SearchFrame = require(script:WaitForChild("SearchFrame"))

--

local CatalogSearchController = {}
CatalogSearchController.__index = CatalogSearchController

function CatalogSearchController.new(parentFrame: Frame)
	local self = setmetatable({}, CatalogSearchController)
	self.parentFrame = parentFrame
	self.scope = Fusion:scoped()
	self.searchAssetCategories = self.scope:Value(AssetFilterCategories.getAllAssetTypes())
	self.searchBundleCategories = self.scope:Value(BundleFilterCategories.getAllRobloxBundleTypes())
	self.searchSort = self.scope:Value(Enum.CatalogSortType.Relevance)
	self.searchResults = self.scope:Value("")
	self.searchText = self.scope:Value("")
	self.currentView = WardrobeGuiState.currentView

	return self
end

function CatalogSearchController:Initialise()
	self:_initialiseCategoryFrame()
	self:_intialiseOutfitFrame()
	self:_initialiseSearchFrame()

	self.searchCallback("swag")
end

function CatalogSearchController:_initialiseCategoryFrame()
	-- Category frame doesn't need positioning props typically
	local categoryFrame = CategoryFrame(self.scope, {
		size = UDim2.fromScale(0.2, 1),
		position = UDim2.fromScale(0.5, 0.5),
		backgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		anchorPoint = Vector2.new(0.5, 0.5),
		layoutOrder = 1,
		backgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
		currentView = self.currentView,
		searchAssetCategories = self.searchAssetCategories, 
		searchBundleCategories = self.searchBundleCategories, 
		searchCallback = self.searchCallback
	})
	 
	categoryFrame.Parent = self.parentFrame
end

function CatalogSearchController:_initialiseSearchFrame()
	-- Define callbacks FIRST
	self.searchCallback = function(keyword: string?)
		if not self.SearchResultsFrame then
			warn("SearchResultsFrame not ready yet")
			return
		end
		
		self.clearCatalogCallback()
		warn("Searching!")

		local catalogParams = CatalogSearchParams.new()
		catalogParams.SearchKeyword = keyword or peek(self.searchText)
		catalogParams.SortType = peek(self.searchSort)
		catalogParams.Limit = 60
		catalogParams.AssetTypes = peek(self.searchAssetCategories)
		catalogParams.BundleTypes = peek(self.searchBundleCategories)

		local success, results = pcall(function()
			return AvatarEditorService:SearchCatalog(catalogParams)
		end)

		if success then
			self.searchResults:set(results)
			for _, itemDetails in pairs(results:GetCurrentPage()) do
				local newTile = FusionItemTile(self.scope, itemDetails)
				newTile.Parent = self.SearchResultsFrame
				print("Newtile parent ", newTile.Parent)
			end
		else
			warn("Failed to search catalog for keyword:", peek(self.searchText))
		end
	end

	self.clearCatalogCallback = function()
		if not self.SearchResultsFrame then return end
		-- clear all children of the searchresults frame
		for _, child in self.SearchResultsFrame:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	-- NOW create SearchFrame with the callbacks defined
	local searchFrame, searchResultsFrame = SearchFrame(self.scope, {
		size = UDim2.fromScale(0.8, 1),
		position = UDim2.fromScale(0.5, 0.5),
		anchorPoint = Vector2.new(0.5, 0.5),
		layoutOrder = 2,
		currentView = self.currentView, 
		backgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
		searchAssetCategories = self.searchAssetCategories, 
		searchBundleCategories = self.searchBundleCategories,
		searchSort = self.searchSort,
		searchResults = self.searchResults,
		searchText = self.searchText, 
		searchCallback = self.searchCallback 
	})    
	
	searchFrame.Parent = self.parentFrame
	self.SearchResultsFrame = searchResultsFrame

	return searchFrame, searchResultsFrame
end

function CatalogSearchController:_intialiseOutfitFrame()
	local outfitsFrame = OutfitsFrame(self.scope, 
		self.currentView
	)
	outfitsFrame.Parent = self.parentFrame
end

function CatalogSearchController:Cleanup()
	if self.scope then
		self.scope:cleanup() 
	end
end

return CatalogSearchController