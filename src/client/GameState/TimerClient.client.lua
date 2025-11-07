--!strict

--[[
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
local UpdateLocalPhaseTimes = Remotes:WaitForChild("UpdateLocalPhaseTimes")

--

local function nextPhaseUpdated(newNextPhaseTime: number)
    LocalTimer.updateNextPhaseStartTime(newNextPhaseTime)
end

local function initialiseLocalTimer()
    LocalTimer.initialiseLocalTimer()
end

initialiseLocalTimer()

UpdateLocalPhaseTimes.OnClientEvent:Connect(nextPhaseUpdated)
]]