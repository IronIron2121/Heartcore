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
    print("Phase changed - determining winners...")
    local success = WinnersStoreManager.setNewWinners()
    if success then
        print("Winners set successfully")
    else
        warn("Failed to set winners")
        WinnersStoreManager.resetWinners()
    end
end

PhaseChanged.Event:Connect(onPhaseChanged)