--!strict
-- AvatarEditorController.lua


-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local WardrobeGuiController = FusionComponents:WaitForChild("WardrobeGuiController")

-- Modules
local EquippedItemButton = require(script.EquippedItemsPanel.EquippedItemButtons.EquippedItemButton)
local Fusion = require(Utility:WaitForChild("Fusion"))
local AvatarPreviewModel = require(script:WaitForChild("AvatarPreviewModel"))
local WardrobeGuiState = require(WardrobeGuiController:WaitForChild("WardrobeGuiState"))

-- Gui Components
local AvatarViewport = require(script:WaitForChild("AvatarViewport"))
local EquippedItemsPanel = require(script:WaitForChild("EquippedItemsPanel"))

-- Fusion Modules
local AvatarEditorController = {}
AvatarEditorController.__index = AvatarEditorController

function AvatarEditorController.new(parentFrame: Frame)
	local self = setmetatable({}, AvatarEditorController)
	self.parentFrame = parentFrame
	self.avatarViewport = nil
	self.scope = Fusion:scoped()

	return self
end

function AvatarEditorController:Initialise()	
	self:_initialiseAvatarViewport()
	self:_initialiseEquippedItemsPanel()
end

function AvatarEditorController:_initialiseAvatarViewport()
	-- Create the avatar preview model
	local avatarPreviewModel = AvatarPreviewModel.new(self.scope)

	-- Pass the reactive instance directly (it's already a Computed)
	self.avatarViewport = AvatarViewport(self.scope, {
		model = avatarPreviewModel:getInstance(),
		currentView = WardrobeGuiState.currentView,
		layoutOrder = 2
	}) 
	
	self.avatarViewport.Parent = self.parentFrame  

	-- Store reference to the avatar preview model
	self.avatarPreviewModel = avatarPreviewModel
end

function AvatarEditorController:_initialiseEquippedItemsPanel()
	-- Pass the avatar preview model instead of trying to use self.model
	self.EquippedItemsPanel = EquippedItemsPanel(self.scope, {
		layoutOrder = 1
	})
	self.EquippedItemsPanel.Parent = self.parentFrame
end

function AvatarEditorController:RemoveEquippedItemTile(assetId: number)
	for _, tile in self.EquippedItemsPanel do
		if tile.Name == assetId or tile.Name == tostring(assetId) then
			tile:Destroy() -- or whatever the fusion equivalent is...
		end
	end
end

function AvatarEditorController:AddEquippedItemTile(asset: number)
	local itemButton = EquippedItemButton(self.scope, {
		buttonSize = UDim2.fromScale(0.7, 0.7)
	})

	itemButton.Parent = self.EquippedItemsPanel
end

-- Simple cleanup
function AvatarEditorController:Cleanup() 
	if self.scope then
		self.scope:cleanup()
	end
	if self.avatarViewport then
		self.avatarViewport:Destroy()
	end 
end

return AvatarEditorController