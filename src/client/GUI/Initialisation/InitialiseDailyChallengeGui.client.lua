--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")

-- GUI Controllers
local DailyChallengeGuiController = require(FusionComponents:WaitForChild("DailyChallengeGuiController"))
 
--

local function initialiseDailyChallengeGui()
	DailyChallengeGuiController.Initialise() 
end

initialiseDailyChallengeGui()