--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- GUI Controllers
local WardrobeGuiController = require(FusionComponents:WaitForChild("WardrobeGuiController"))

-- Fusion Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local peek = Fusion.peek
local Children = Fusion.Children

-- Fusion Values
local scope = Fusion:scoped()

local CatalogButtonToggled = scope:Value(false)

-- Modules
local ImageUris = require(DataTables:WaitForChild("ImageUris"))

-- Player
local localPlayer = Players.LocalPlayer
 
--

local function initialiseWardrobeGui()
	WardrobeGuiController.Initialise() 
end

initialiseWardrobeGui()