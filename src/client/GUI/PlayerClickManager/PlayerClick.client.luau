--!strict

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Libraries         = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerFolder  = Libraries.GuiManager
local Utility           = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local MODAL_NAMES   = require(ReplicatedStorage.Libraries.GuiManager.MODAL_NAMES)
local GuiManager    = require(GuiManagerFolder.GuiManager) 

-- Fusion
local Fusion        = require(Utility.Fusion)
local clickScope    = Fusion:scoped()
local OnEvent       = Fusion.OnEvent

-- Instances
local localPlayer = Players.LocalPlayer
local hoverHighlight = Instance.new("Highlight", script)
hoverHighlight.Name = "Hover_Highlight"

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
            GuiManager.PushCentreByName(MODAL_NAMES.PLAYER_INSPECT_GUI, {player = player, rig = nil})
        end,

        [OnEvent "MouseHoverEnter"] = function()
            hoverHighlight.Adornee = character
        end,

        [OnEvent "MouseHoverLeave"] = function()
            hoverHighlight.Adornee = nil
        end
    } :: ClickDetector

    clickDetector.Parent = character
end

local function addClickDetectorToWinnerRig(rig: Model)
    warn("Adding to winner rig ", rig)
    local activationDistanceComp = clickScope:Computed(function(use)
        return use(CentreActive) and 0 or 20
    end)
    
    local clickDetector = clickScope:New "ClickDetector" {
        MaxActivationDistance = activationDistanceComp,

        [OnEvent "MouseClick"] = function()
            GuiManager.PushCentreByName(MODAL_NAMES.PLAYER_INSPECT_GUI, {player = nil, rig = rig})
        end,

        [OnEvent "MouseHoverEnter"] = function()
            hoverHighlight.Adornee = rig
        end,

        [OnEvent "MouseHoverLeave"] = function()
            hoverHighlight.Adornee = nil
        end
    } :: ClickDetector

    clickDetector.Parent = rig
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

CollectionService:GetInstanceAddedSignal("WinnerRig"):Connect(function(rig: Model) 
    addClickDetectorToWinnerRig(rig)
end)

local function initWinnerRigs()
    warn("init")
    local winnerRigs = CollectionService:GetTagged("WinnerRig")
    warn(winnerRigs)
    for _, rig in winnerRigs do
        addClickDetectorToWinnerRig(rig)
    end

end

initWinnerRigs() 