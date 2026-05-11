--!strict

-- Services 
local Players = game:GetService("Players")

-- Constants
local PLAYER_DISPLAY_NAME = "PlayerDisplayBillboard"

--

local PlayerDisplayManager = {}

function PlayerDisplayManager.HideAllDisplays()
    for _, player in Players:GetPlayers() do
        local char = player.Character or player.CharacterAdded:Wait()
        if not char then return end

        local PDB = char:FindFirstChild(PLAYER_DISPLAY_NAME)
        if not PDB then continue end

        PDB.Enabled = false
    end
end

function PlayerDisplayManager.ShowAllDisplays()
    for _, player in Players:GetPlayers() do
        local char = player.Character or player.CharacterAdded:Wait()
        if not char then return end

        local PDB = char:FindFirstChild(PLAYER_DISPLAY_NAME)
        if not PDB then 
            warn("No player display at player ", player.Name) 
        else
            PDB.Enabled = true
        end
    end
end

return PlayerDisplayManager