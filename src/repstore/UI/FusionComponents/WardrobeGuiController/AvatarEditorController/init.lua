--!strict
-- AvatarEditorController.lua

-- Services
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
	local avatarPreviewModel = AvatarPreviewModel.new(self.scope)

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
	self.EquippedItemsPanel = EquippedItemsPanel(self.scope, {
		layoutOrder = 1
	})
	self.EquippedItemsPanel.Parent = self.parentFrame
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
end

function AvatarEditorController:_addEquippedItemTile(description: AccessoryDescription | BodyPartDescription)
	local tile = EquippedItemButton(self.scope, {
		buttonSize = UDim2.fromScale(0.7, 0.7),
		visible = true,
		itemDescription = description,
		removeCb = function()
			ClientCustomisationService.RemoveItem(description.AssetId)
			self:RemoveEquippedItemTile(description.AssetId)
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
			warn("Removing in CB!")
			ClientCustomisationService.RemoveClassicItem(assetId, itemType)
			self:RemoveClassicItemTile(itemType)
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
	warn("removing classic item tile")
	warn(self.classicTiles)
	warn(itemType)
	local tile = self.classicTiles[itemType]
	if tile then
		tile:Destroy()
		self.classicTiles[itemType] = nil
		warn("Found a tile for destroyed classic")
	else
		warn("No tile for destroyed classic")
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