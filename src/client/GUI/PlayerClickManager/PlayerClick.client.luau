--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Libraries         = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerFolder  = Libraries.GuiManager
local Utility           = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local MODAL_NAMES   = require(ReplicatedStorage.Libraries.GuiManager.MODAL_NAMES)
local ChallengeCard = require(ReplicatedStorage.UI.FusionComponents.Widgets.ChallengeCard)
local GuiManager    = require(GuiManagerFolder.GuiManager) 

-- Fusion
local Fusion        = require(Utility.Fusion)
local clickScope    = Fusion:scoped()
local OnEvent       = Fusion.OnEvent

-- Instances
local localPlayer = Players.LocalPlayer

-- Constants
local CLICK_DETECTOR_NAME = "OD"

-- Variables
local CentreActive = GuiManager.GetCentreActiveValue()

--

local function addClickDetector(player: Player, character: Model?)
    character = character or player.Character or player.CharacterAdded:Wait()
    if character and character:FindFirstChild(CLICK_DETECTOR_NAME) then
        return
    end

    local activationDistanceComp = clickScope:Computed(function(use)
        return use(CentreActive) and 0 or 20
    end)
    
    local clickDetector = clickScope:New "ClickDetector" {
        MaxActivationDistance = activationDistanceComp,

        [OnEvent "MouseClick"] = function()
            GuiManager.PushCentreByName(MODAL_NAMES.PLAYER_INSPECT_GUI)
        end

    } :: ClickDetector

    clickDetector.Parent = character
end

-- Add click detectors to all players in game when local player joins
local function onPlayerJoin()   
    for _, player in Players:GetPlayers() do
        if player.UserId ~= localPlayer.UserId then
            addClickDetector(player)
        end
    end
end

onPlayerJoin()

-- Add click detectors to all players who join or respawn after local player joins
Players.PlayerAdded:Connect(function(player)
    if player.UserId == localPlayer.UserId then return end

    player.CharacterAdded:Connect(function(character)
        addClickDetector(player, character)
    end)
    
    -- If character already exists
    if player.Character then
        addClickDetector(player, player.Character)
    end
end)