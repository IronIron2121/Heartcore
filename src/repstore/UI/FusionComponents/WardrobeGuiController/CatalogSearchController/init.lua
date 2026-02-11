--!strict

-- CatalogSearchController.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")
local ScriptCommitService = game:GetService("ScriptCommitService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local WardrobeGuiController = FusionComponents:WaitForChild("WardrobeGuiController")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local AvatarPreviewModel = require(ReplicatedStorage.UI.FusionComponents.WardrobeGuiController.AvatarEditorController.AvatarPreviewModel)
local AvatarEditorController = require(script.Parent.AvatarEditorController)
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local AssetFilterCategories = require(DataTables:WaitForChild("AssetFilterCategories"))
local BundleFilterCategories = require(DataTables:WaitForChild("BundleFilterCategories"))
local WardrobeGuiState = require(WardrobeGuiController:WaitForChild("WardrobeGuiState"))
local FusionItemTile = require(Widgets:WaitForChild("FusionItemTile"))
local EditorsPick = require(DataTables:WaitForChild("EditorsPick"))

-- Fusion Components
local Fusion = require(Utility:WaitForChild("Fusion"))
local peek = Fusion.peek

-- GUI Components
local CategoryFrame = require(script:WaitForChild("CategoryFrame"))
local OutfitsFrame = require(script:WaitForChild("OutfitsFrame"))
local SearchFrame = require(script:WaitForChild("SearchFrame"))
local InspectFrame = require(script:WaitForChild("InspectFrame"))

-- Constants

local sortTextToSortType = {
	["Relevance"] = Enum.CatalogSortType.Relevance,
	["Bestselling"] = Enum.CatalogSortType.Bestselling,
	["Most Favorited"] = Enum.CatalogSortType.MostFavorited,
	["Price High To Low"] = Enum.CatalogSortType.PriceHighToLow,
	["Price Low To High"] = Enum.CatalogSortType.PriceLowToHigh,
	["Recently Created"] = Enum.CatalogSortType.RecentlyCreated,
}

--

local CatalogSearchController = {}
CatalogSearchController.__index = CatalogSearchController

function CatalogSearchController.new(parentFrame: Frame, controllers: {any})
	local self = setmetatable({}, CatalogSearchController)
	self.parentFrame = parentFrame
	self.scope = Fusion:scoped()
	self.searchAssetCategories = self.scope:Value(AssetFilterCategories.getAllAssetTypes())
	self.searchBundleCategories = self.scope:Value(BundleFilterCategories.getAllRobloxBundleTypes())
	self.searchSort = self.scope:Value(Enum.CatalogSortType.Relevance.Name)
	self.searchResults = self.scope:Value("")
	self.searchText = self.scope:Value("")
	self.currentView = WardrobeGuiState.currentView
	self.controllers = controllers

	return self
end

function CatalogSearchController:Initialise()
	self:_intialiseOutfitFrame()
	self:_initialiseSearchFrame()
	self:_initialiseCategoryFrame()
	self:_initialiseInspectFrame()

	EditorsPick.initialiseItemDetails()
 	self.editorsPickCallback()
end

function CatalogSearchController:_initialiseCategoryFrame()
	-- Category frame doesn't need positioning props typically
	local categoryFrame = CategoryFrame(self.scope, {
		size = UDim2.fromScale(0.15, 1),
		position = UDim2.fromScale(0.5, 0.5),
		backgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		anchorPoint = Vector2.new(0.5, 0.5),
		layoutOrder = 1,
		backgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
		currentView = self.currentView,
		searchAssetCategories = self.searchAssetCategories, 
		searchBundleCategories = self.searchBundleCategories, 
		searchCallback = self.searchCallback,
		editorsPickCallback = self.editorsPickCallback,
		editorsPickSelected = self.editorsPickSelected
	})
	 
	categoryFrame.Parent = self.parentFrame
end

function CatalogSearchController:_initialiseSearchFrame()
    self.isLoadingMore = false
    
    self.loadMoreCallback = function()
        if self.isLoadingMore or peek(self.editorsPickSelected) or not self.SearchResultsFrame or peek(self.searchResults).isFinished then 
			warn("Returning before loadmore...", self.isLoadingMore, peek(self.editorsPickSelected), self.SearchResultsFrame, peek(self.searchResults).isFinished)
			return 
		end
		warn("Loading more!") 
        self.isLoadingMore = true
        
        -- Load next page
        local success, nextPageResults = pcall(function()
            return peek(self.searchResults):AdvanceToNextPageAsync()
        end)
        
        if success then
			warn("making new tiles!")
			local numChildren = #self.SearchResultsFrame:GetChildren()
			for index, itemDetails in ipairs(peek(self.searchResults):GetCurrentPage()) do
				local newTile = FusionItemTile(self.scope, {
					itemDetails = itemDetails,
					layoutOrder = numChildren + index,
					onTryCb = function()
						if itemDetails.AssetType == Enum.AssetType.EmoteAnimation.Name then
							self.controllers.AvatarEditorController.avatarPreviewModel:PlayAnimation(itemDetails.Id)
						end
					end
				})

				newTile.Parent = self.SearchResultsFrame
			end
		else
			warn("Failed to load more!", success, nextPageResults)
        end
         
        self.isLoadingMore = false
    end

	self.editorsPickSelected = self.scope:Value(false)

	self.searchCallback = function(keyword: string?)
		keyword = keyword or "   "
		if not self.SearchResultsFrame then
			warn("SearchResultsFrame not ready yet")
			return
		end

		self.editorsPickSelected:set(false)
		
		self.clearCatalogCallback()
		warn("Searching!", peek(self.editorsPickSelected))

		local catalogParams = CatalogSearchParams.new()
		catalogParams.SearchKeyword = keyword or peek(self.searchText)
		catalogParams.SortType = sortTextToSortType[peek(self.searchSort)]
		--catalogParams.MinPrice = 0
		--catalogParams.MaxPrice = math.huge
		--catalogParams.SortAggregation = Enum.CatalogSortAggregation.AllTime
		--catalogParams.SalesTypeFilter = Enum.SalesTypeFilter.All
		--catalogParams.CategoryFilter = Enum.CatalogCategoryFilter.None
		catalogParams.Limit = 60
		catalogParams.AssetTypes = peek(self.searchAssetCategories)
		catalogParams.BundleTypes = peek(self.searchBundleCategories)

		local success, results = pcall(function()
			return AvatarEditorService:SearchCatalogAsync(catalogParams)
		end)

		if success then
			self.searchResults:set(results)
			for index, itemDetails in ipairs(results:GetCurrentPage()) do
				local newTile = FusionItemTile(self.scope, {
					itemDetails = itemDetails,
					layoutOrder = index,
					onTryCb = function()
						if itemDetails.AssetType == Enum.AssetType.EmoteAnimation.Name then
							self.controllers.AvatarEditorController.avatarPreviewModel:PlayAnimation(itemDetails.Id)
						end
					end
				})
				newTile.Parent = self.SearchResultsFrame
			end
		else
			warn("Failed to search catalog for keyword:", peek(self.searchText), success, results)
		end
	end

	self.editorsPickCallback = function()
		if not self.SearchResultsFrame then
			warn("SearchResultsFrame not ready yet")
			return
		end

		self.clearCatalogCallback()

		for index, itemDetails in ipairs(EditorsPick.itemDetails) do
			local newTile = FusionItemTile(self.scope, {
				itemDetails = itemDetails,
				layoutOrder = index,
				onTryCb = function()
					if itemDetails.AssetType == Enum.AssetType.EmoteAnimation.Name then
						self.controllers.AvatarEditorController.avatarPreviewModel:PlayAnimation(itemDetails.Id)
					end
				end
			})
			newTile.Parent = self.SearchResultsFrame
		end

		self.searchBundleCategories:set({})
		self.searchAssetCategories:set({})

		self.editorsPickSelected:set(true)
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
		size = UDim2.fromScale(0.84, 1),
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
		loadMoreCallback = self.loadMoreCallback,
		searchCallback = self.searchCallback,
	})    
	
	searchFrame.Parent = self.parentFrame
	self.SearchResultsFrame = searchResultsFrame

	return searchFrame, searchResultsFrame
end

function CatalogSearchController:_intialiseOutfitFrame()
	self.outfitsFrame, self.updatePlayerOutfits = OutfitsFrame(self.scope, {
		currentView = self.currentView
	})
	
	self.outfitsFrame.Parent = self.parentFrame
end

function CatalogSearchController:_initialiseInspectFrame()
	local inspectFrame = InspectFrame(self.scope, {
		currentView = self.currentView
	})

	inspectFrame.Parent = self.parentFrame
end

function CatalogSearchController:Cleanup()
	if self.scope then
		self.scope:cleanup() 
	end
end

return CatalogSearchController