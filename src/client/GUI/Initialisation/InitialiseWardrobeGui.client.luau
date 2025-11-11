--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")

-- GUI Controllers
local WardrobeGuiController = require(FusionComponents:WaitForChild("WardrobeGuiController"))

--

local function initialiseWardrobeGui()
	WardrobeGuiController.Initialise() 
end

initialiseWardrobeGui()