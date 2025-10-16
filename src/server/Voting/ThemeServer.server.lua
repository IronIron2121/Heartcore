--!strict

-- Servers
local ServerScriptsService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Voting = ServerScriptsService:WaitForChild("Voting")

-- Modules
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local ThemeManager = require(Voting:WaitForChild("ThemeManager"))

-- Remotes / Bindables
local PlayerRequestedCurrentTheme = Remotes:WaitForChild("PlayerRequestedCurrentTheme")
local PhasedChanged = Bindables:WaitForChild("PhaseChanged")

local function onPhaseChanged()
    ThemeManager.onPhaseTransition()
    SubmissionStoreManager.onThemeTransition()
end

local function playerRequestedCurrentTheme()
    return ThemeManager.getCurrentThemeName()
end

PhasedChanged.Event:Connect(onPhaseChanged)  
PlayerRequestedCurrentTheme.OnServerInvoke = playerRequestedCurrentTheme