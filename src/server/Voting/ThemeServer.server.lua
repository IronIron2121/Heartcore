--!strict

-- Servers
local ServerScriptsService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Voting = ServerScriptsService:WaitForChild("Voting")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local ThemeManager = require(Voting:WaitForChild("ThemeManager"))

-- Remotes / Bindables
local PhasedChanged = Bindables:WaitForChild("PhaseChanged")

local function onPhaseChanged()
    ThemeManager.onPhaseTransition()
    SubmissionStoreManager.onThemeTransition()
end

PhasedChanged.Event:Connect(onPhaseChanged)  