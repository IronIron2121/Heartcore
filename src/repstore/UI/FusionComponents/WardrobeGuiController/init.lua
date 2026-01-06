--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- FusionComponents
local WardrobeGui = require(script:WaitForChild("WardrobeGui"))

-- Controllers
local AvatarEditorController = require(script:WaitForChild("AvatarEditorController")) 
local CatalogSearchController = require(script:WaitForChild("CatalogSearchController")) 
local OutfitViewController = require(script:WaitForChild("OutfitViewController"))

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
type UsedAs<T> = Fusion.UsedAs<T>

--

local WardrobeGuiController = {}

-- TODO: I think it would make more sense if we initialiased the mainhud elsewhere, but this will do for now
function WardrobeGuiController.Initialise()
	-- Get the open outfit catalog button so we can pass it to the catalog gui that uses it
	local WardrobeGui, AvatarContainer, CatalogContainer = WardrobeGui()
	
	-- The above just initialises the surrounding framework
	-- The actual avatar interaction gui (preview viewport, equipment tracking) will be initialised in the "AvatarEditorController" itself - 


end 

return WardrobeGuiController