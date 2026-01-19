--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Voting = ServerScriptService:WaitForChild("Voting")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Modules
local WinnersStoreManager = require(Voting:WaitForChild("WinnersStoreManager")) 

-- Bindables
local PhaseChanged = Bindables:WaitForChild("PhaseChanged")

--

local function onPhaseChanged()
    local success = WinnersStoreManager.setNewWinners()
    if not success then
        WinnersStoreManager.resetWinners()
    end
end

PhaseChanged.Event:Connect(onPhaseChanged)