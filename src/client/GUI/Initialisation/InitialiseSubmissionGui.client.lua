--!strict

-- Services
local StarterPlayer = game:GetService("StarterPlayer")

-- Folders
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GUI = StarterPlayerScripts:WaitForChild("GUI")

-- Modules
local SubmissionGuiController = require(GUI:WaitForChild("SubmissionGuiController"))

--

local function initialiseSubmissionController()
    SubmissionGuiController.Initialise(SubmissionGuiVisible, TimeText)
end