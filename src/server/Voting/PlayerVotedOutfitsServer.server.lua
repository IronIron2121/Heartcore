--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local PlayerVotedOutfitsTracker = require(Voting:WaitForChild("PlayerVotedOutfitsTracker"))

-- Remotes / Bindables
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")

--

local function onPhaseChanged()
    PlayerVotedOutfitsTracker.ResetPlayerList()
end

PhaseChanged.Event:Connect(onPhaseChanged)