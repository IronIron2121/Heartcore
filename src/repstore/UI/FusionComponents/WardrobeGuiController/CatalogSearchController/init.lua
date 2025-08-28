--!strict
-- CatalogSearchController.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local AssetFilterCategories = require(DataTables:WaitForChild("AssetFilterCategories"))
local BundleFilterCategories = require(DataTables:WaitForChild("BundleFilterCategories"))
local WardrobeGuiState = require(script.Parent:WaitForChild("WardrobeGuiState"))

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
	self.currentView = WardrobeGuiState.currentView

	return self
end

function CatalogSearchController:Initialise()
	self:_initialiseCategoryFrame()
	self:_initialiseSearchFrame()
	self:_intialiseOutfitFrame()
end

function CatalogSearchController:_initialiseCategoryFrame()
	-- Category frame doesn't need positioning props typically
	local categoryFrame = CategoryFrame(self.scope, 
		self.currentView,
		self.searchAssetCategories, 
		self.searchBundleCategories, 
		{
			size = UDim2.fromScale(0.2, 1),
			position = UDim2.fromScale(0.5, 0.5),
			backgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
			anchorPoint = Vector2.new(0.5, 0.5),
			layoutOrder = 1,
			backgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT
		})
	 
	categoryFrame.Parent = self.parentFrame
end

function CatalogSearchController:_initialiseSearchFrame()
	local searchFrame = SearchFrame(self.scope, 
		self.currentView, 
		self.searchAssetCategories,
		self.searchBundleCategories, 
		{
			size = UDim2.fromScale(0.8, 1),
			position = UDim2.fromScale(0.5, 0.5),
			anchorPoint = Vector2.new(0.5, 0.5),
			layoutOrder = 2,
			backgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
		})

	searchFrame.Parent = self.parentFrame
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