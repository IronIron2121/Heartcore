--!strict

-- Services
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GameState = StarterPlayerScripts:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local LocalTimer = require(GameState:WaitForChild("LocalTimer"))

-- Remotes / Bindables
local UpdateAllLocalNextPhaseStartTimes = Remotes:WaitForChild("UpdateAllLocalNextPhaseStartTimes")

--

local function nextPhaseUpdated(newNextPhaseTime: number)
    LocalTimer.updateNextPhaseStartTime(newNextPhaseTime)
end

local function initialiseLocalTimer()
    LocalTimer.initialiseLocalTimer()
    print("Local timer initialised")
end

initialiseLocalTimer()

UpdateAllLocalNextPhaseStartTimes.OnClientEvent:Connect(nextPhaseUpdated)