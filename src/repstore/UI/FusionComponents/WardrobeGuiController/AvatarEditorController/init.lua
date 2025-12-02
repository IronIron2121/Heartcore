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
		currentView = WardrobeGuiState.currentView
	}) 
	
	self.avatarViewport.Parent = self.parentFrame  

	-- Store reference to the avatar preview model
	self.avatarPreviewModel = avatarPreviewModel
end

function AvatarEditorController:_initialiseEquippedItemsPanel()
	-- Pass the avatar preview model instead of trying to use self.model
	local EquippedItemsPanel = EquippedItemsPanel(self.scope)
	EquippedItemsPanel.Parent = self.parentFrame
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