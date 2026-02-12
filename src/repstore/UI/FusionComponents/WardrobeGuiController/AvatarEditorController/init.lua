--!strict
-- AvatarEditorController.lua

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local WardrobeGuiController = FusionComponents:WaitForChild("WardrobeGuiController")

-- Modules
local EquippedItemButton = require(script.EquippedItemsPanel.EquippedItemButtons.EquippedItemButton)
local EquippedClassicItemButton = require(script.EquippedItemsPanel.EquippedItemButtons.EquippedClassicItemButton)
local Fusion = require(Utility:WaitForChild("Fusion"))
local AvatarPreviewModel = require(script:WaitForChild("AvatarPreviewModel"))
local WardrobeGuiState = require(WardrobeGuiController:WaitForChild("WardrobeGuiState"))
local ClientCustomisationService = require(StarterPlayer.StarterPlayerScripts.Clothing.ClientCustomisationService)
local Constants = require(ReplicatedStorage.Constants)
local LoadingScreenManager = require(ReplicatedStorage.Libraries.LoadingScreenManager)
local callWithRetry = require(ReplicatedStorage.Utility.callWithRetry)

-- Gui Components
local AvatarViewport = require(script:WaitForChild("AvatarViewport"))
local EquippedItemsPanel = require(script:WaitForChild("EquippedItemsPanel"))

-- Constants
local CLASSIC_ITEMS = {"GraphicTShirt", "Shirt", "Pants", "Face"}

-- Types
type ItemTile = Frame

local AvatarEditorController = {}
AvatarEditorController.__index = AvatarEditorController

function AvatarEditorController.new(parentFrame: Frame, controllers: {})
	local self = setmetatable({}, AvatarEditorController)
	self.parentFrame = parentFrame
	self.avatarViewport = nil
	self.scope = Fusion:scoped()
	self.controllers = controllers
	
	-- Manual tile tracking
	self.equippedTiles = {} :: {[number]: ItemTile}  -- assetId -> tile
	self.classicTiles = {} :: {[string]: ItemTile}   -- itemType -> tile
	
	return self
end

function AvatarEditorController:Initialise()
	local localPlayer = Players.LocalPlayer
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	self.character = char
	self.humanoid = char:WaitForChild("Humanoid") :: Humanoid
	
	self:_initialiseAvatarViewport()
	self:_initialiseEquippedItemsPanel()
	self:_watchForItemChanges()
	
	-- Initial sync
	local humDesc = self.humanoid:FindFirstChild("HumanoidDescription")
	if humDesc then 
		self:_syncItemsFromDescription(humDesc)
	end
end

function AvatarEditorController:_initialiseAvatarViewport()
	local avatarPreviewModel = AvatarPreviewModel.new(self.scope, {
		showLoading = function()
			if self.avatarViewport then LoadingScreenManager.show(self.avatarViewport) end
		end,
		hideLoading = function()
			if self.avatarViewport then LoadingScreenManager.hide(self.avatarViewport) end
		end,
	})
	self.avatarViewport = AvatarViewport(self.scope, {
		model = avatarPreviewModel:getInstance(),
		currentView = WardrobeGuiState.currentView,
		layoutOrder = 2,
		controllers = self.controllers
	})
	
	self.avatarViewport.Parent = self.parentFrame
	self.avatarPreviewModel = avatarPreviewModel
end

function AvatarEditorController:_initialiseEquippedItemsPanel()
	self.EquippedItemsContainer, self.EquippedItemsPanel = EquippedItemsPanel(self.scope, {
		layoutOrder = 1
	})
	self.EquippedItemsContainer.Parent = self.parentFrame
end

function AvatarEditorController:_watchForItemChanges()
	-- Watch for HumanoidDescription changes
	self.humanoid.ChildAdded:Connect(function(child)
		if child:IsA("HumanoidDescription") then
			self:_syncItemsFromDescription(child)
		end
	end)
end

function AvatarEditorController:_syncItemsFromDescription(humDesc: HumanoidDescription)
	LoadingScreenManager.show(self.EquippedItemsContainer)
	local currentAssetIds = {}
	local currentClassicItems = {}
	
	-- Collect current asset IDs from descriptions
	for _, desc in humDesc:GetChildren() do
		if (desc:IsA("AccessoryDescription") or desc:IsA("BodyPartDescription")) and desc.AssetId ~= 0 then
			currentAssetIds[desc.AssetId] = desc
		end
	end
	
	-- Collect classic items
	for _, itemType in CLASSIC_ITEMS do
		local assetId = humDesc[itemType]
		if assetId and assetId ~= 0 then
			currentClassicItems[itemType] = assetId
		end
	end
	
	-- Add new tiles that don't exist yet
	for assetId, desc in currentAssetIds do
		if not self.equippedTiles[assetId] then
			warn("adding item tile")
			self:_addEquippedItemTile(desc)
		end
	end
	
	-- Add new classic tiles
	for itemType, assetId in currentClassicItems do
		if not self.classicTiles[itemType] then
			warn("adding classic item tile")
			self:_addClassicItemTile(assetId, itemType)
		end
	end
	
	-- Remove tiles that no longer exist
	for assetId, tile in self.equippedTiles do
		if not currentAssetIds[assetId] then
			tile:Destroy()
			self.equippedTiles[assetId] = nil
		end
	end
	
	-- Remove classic tiles that no longer exist
	for itemType, tile in self.classicTiles do
		if not currentClassicItems[itemType] then
			tile:Destroy()
			self.classicTiles[itemType] = nil
		end
	end
	LoadingScreenManager.hide(self.EquippedItemsContainer)
end

function AvatarEditorController:_addEquippedItemTile(description: AccessoryDescription | BodyPartDescription)
	local tile = EquippedItemButton(self.scope, {
		buttonSize = UDim2.fromScale(0.7, 0.7),
		visible = true,
		itemDescription = description,

		buyCb = function()
			LoadingScreenManager.show(self.parentFrame)
			task.defer(function()
				local success = callWithRetry(function()
					return MarketplaceService:PromptPurchase(Players.LocalPlayer, description.AssetId)
				end)

				if not success then 
					warn("Failed to purchase item")	
				end

				LoadingScreenManager.hide(self.parentFrame)
			end)
		end,

		removeCb = function()
			LoadingScreenManager.show(self.EquippedItemsContainer)
			local success = ClientCustomisationService.RemoveItem(description.AssetId)
			
			if success then
				self:RemoveEquippedItemTile(description.AssetId)
			end
			LoadingScreenManager.hide(self.EquippedItemsContainer)
		end
	})
	
	tile.Parent = self.EquippedItemsPanel
	self.equippedTiles[description.AssetId] = tile
end

function AvatarEditorController:_addClassicItemTile(assetId: number, itemType: string)
	local tile = EquippedClassicItemButton(self.scope, {
		buttonSize = UDim2.fromScale(0.7, 0.7),
		visible = true,
		itemId = assetId,
		itemType = itemType,
		removeCb = function()
			LoadingScreenManager.show(self.EquippedItemsContainer)
			if table.find(Constants.DEFAULT_CLASSIC_CLOTHING_IDS_TABLE, assetId) then
				return true
			end
			local success = ClientCustomisationService.RemoveClassicItem(assetId, itemType)
			if success then
				self:RemoveClassicItemTile(itemType)
			else
				warn("Failed to remove classic item", assetId, itemType)
			end
			LoadingScreenManager.hide(self.EquippedItemsContainer)
		end
	})
	
	tile.Parent = self.EquippedItemsPanel
	self.classicTiles[itemType] = tile
end

-- Public API for external use
function AvatarEditorController:RemoveEquippedItemTile(assetId: number)
	local tile = self.equippedTiles[assetId]
	if tile then
		tile:Destroy()
		self.equippedTiles[assetId] = nil
	end
end

function AvatarEditorController:RemoveClassicItemTile(itemType: string)
	local tile = self.classicTiles[itemType]
	if tile then
		tile:Destroy()
		self.classicTiles[itemType] = nil
	else
		warn("Failed to find tile!")
	end
end

function AvatarEditorController:AddEquippedItemTile(description: AccessoryDescription | BodyPartDescription)
	if not self.equippedTiles[description.AssetId] then
		self:_addEquippedItemTile(description)
	end
end

function AvatarEditorController:RefreshAllTiles()
	local humDesc = self.humanoid:FindFirstChild("HumanoidDescription")
	if humDesc then
		self:_syncItemsFromDescription(humDesc)
	end
end

function AvatarEditorController:Cleanup()
	-- Destroy all tiles
	for _, tile in self.equippedTiles do
		tile:Destroy()
	end
	
	for _, tile in self.classicTiles do
		tile:Destroy()
	end
	
	self.equippedTiles = {}
	self.classicTiles = {}
	
	if self.scope then
		self.scope:cleanup()
	end
	if self.avatarViewport then
		self.avatarViewport:Destroy()
	end
end

return AvatarEditorController