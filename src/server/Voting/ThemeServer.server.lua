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
local PlayerRequestedVotingTheme = Remotes:WaitForChild("PlayerRequestedVotingTheme")

local PhasedChanged = Bindables:WaitForChild("PhaseChanged")

local function onPhaseChanged()
    ThemeManager.onPhaseTransition()
    SubmissionStoreManager.onThemeTransition()
end


-- Get current theme from server to client
local function playerRequestedCurrentTheme()
    return ThemeManager.getCurrentThemeName()
end


-- Get voting theme from server to client

local function playerRequestedVotingTheme()
    return ThemeManager.getPreviousPhaseTheme().theme
end

PhasedChanged.Event:Connect(onPhaseChanged)  
PlayerRequestedVotingTheme.OnServerInvoke = playerRequestedVotingTheme
PlayerRequestedCurrentTheme.OnServerInvoke = playerRequestedCurrentTheme