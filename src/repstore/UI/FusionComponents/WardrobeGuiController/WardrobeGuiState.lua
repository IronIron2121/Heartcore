--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local scope = Fusion:scoped()

-- Constants
local DEFAULT_VIEW = "Catalog"

--

-- TODO: this should be updated to be a state machine in time, but for now this will do.
local WardrobeGuiState = {
	currentView = scope:Value(DEFAULT_VIEW)
}

function WardrobeGuiState.ResetView()
	WardrobeGuiState.currentView:set(DEFAULT_VIEW)
end

function WardrobeGuiState.ChangeCurrentView(newView: string)
	WardrobeGuiState.currentView:set(newView)
end

return WardrobeGuiState