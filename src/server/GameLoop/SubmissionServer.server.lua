-- SubmissionServer.lua
-- Players submit outfit for the current round.

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Getters = ReplicatedStorage:WaitForChild("Getters")
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))
local GameStateManager = require(GameLoop:WaitForChild("GameStateManager"))

-- Remotes
local PlayerSubmittedOutfitRF = Remotes:WaitForChild("PlayerSubmittedOutfit") :: RemoteFunction

--

local function onOutfitSubmitted(player: Player)
    -- Only allow submissions during Dressing phase
    if GameStateManager.getCurrentState() ~= "Dressing" then
		warn("Game is not in dressing state.")
        return
    end

    -- Get humanoid description
    local humanoidDescription = getHumanoidDescriptionFromPlayer(player)
    if not humanoidDescription then
        warn("No Humanoid Description when submitting for player", player.Name)
        return
    end

    -- Clone to snapshot at submission time; the live instance may mutate or be destroyed
    humanoidDescription = humanoidDescription:Clone()
    GameOutfitManager.submitOutfit(player, humanoidDescription)
    GameStateManager.checkAllSubmitted()
end

-- Handle RemoteFunction calls from GUI
PlayerSubmittedOutfitRF.OnServerInvoke = function(player: Player)
    onOutfitSubmitted(player)
end