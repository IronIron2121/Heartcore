--!strict
-- AvatarEditorController.lua
-- GOAL: Just show a 3D avatar. That's it. Nothing else.


-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local AvatarModelFactory = require(Utility:WaitForChild("AvatarModelFactory"))
local AvatarPreviewModel = require(script:WaitForChild("AvatarPreviewModel"))

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
	self.avatarViewport = AvatarViewport(self.scope, avatarPreviewModel:getInstance()) 
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