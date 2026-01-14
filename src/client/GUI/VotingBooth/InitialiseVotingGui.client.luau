--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")


-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local centralPond = workspace:WaitForChild("centralPond")

-- Instances
local pondModel = centralPond:WaitForChild("centralPond")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))


-- Fusion Modules
local scope = Fusion:scoped()
local peek = Fusion.peek

-- Variables
local VoteGuiVisible = scope:Value(false)
local TimeText = scope:Value("Loading...")

