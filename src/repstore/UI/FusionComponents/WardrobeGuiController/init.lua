--!strict

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")

-- FusionComponents
local WardrobeGui = require(script:WaitForChild("WardrobeGui"))
local MainHudGui = require(script:WaitForChild("MainHudGui"))
local OpenWardrobeButton = require(FusionComponents:WaitForChild("OpenWardrobeButton"))

-- Controllers
local AvatarEditorController = require(script:WaitForChild("AvatarEditorController")) 
local CatalogSearchController = require(script:WaitForChild("CatalogSearchController")) 
local OutfitViewController = require(script:WaitForChild("OutfitViewController"))

-- Instances
local localPlayer = Players.LocalPlayer
local localPlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))

--

local WardrobeGuiController = {}

-- TODO: I think it would make more sense if we initialiased the mainhud elsewhere, but this will do for now
function WardrobeGuiController.Initialise()
	-- Get the open outfit catalog button so we can pass it to the catalog gui that uses it
	local MainHudGui, WardrobeButtonToggled = MainHudGui()
	local WardrobeGui, AvatarContainer, CatalogContainer = WardrobeGui(WardrobeButtonToggled) 
	
	-- The above just initialises the surrounding framework
	-- The actual avatar interaction gui (preview viewport, equipment tracking) will be initialised in the "AvatarEditorController" itself - 
	local controllers = {}
	controllers["AvatarEditorController"] = AvatarEditorController.new(AvatarContainer) 
	controllers["CatalogSearchController"] = CatalogSearchController.new(CatalogContainer) 
	controllers["OutfitViewController"] = OutfitViewController
	
	controllers["AvatarEditorController"]:Initialise()
	controllers["CatalogSearchController"]:Initialise()
end 

return WardrobeGuiController 
