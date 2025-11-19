--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Constants
local DEFAULT_VIEW = "Catalog"

local scope = Fusion:scoped()

-- TODO: this should be updated to be a state machine in time, but for now this will do.
local WardrobeGuiState = {
	currentView = scope:Value(DEFAULT_VIEW)
}

return WardrobeGuiState