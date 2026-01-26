--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerFolder = Libraries.GuiManager

-- Modules
local GuiManager = require(GuiManagerFolder.GuiManager) 

-- Instances
local localPlayer = Players.LocalPlayer

-- Constants
local CLICK_DETECTOR_NAME = "OD"

--

local function addClickDetector(player: Player, character: Model?)
    character = character or player.Character or player.CharacterAdded:Wait()
    if character and character:FindFirstChild(CLICK_DETECTOR_NAME) then
        return
    end
    
    local clickDetector = Instance.new("ClickDetector")
    
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = character
    
    clickDetector.MouseClick:Connect(function()
        -- Open modal with that player's info
        warn("Clicking!")
        GuiManager.PushCentreByName("PLAYER_INSPECT_MODAL")
    end)
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