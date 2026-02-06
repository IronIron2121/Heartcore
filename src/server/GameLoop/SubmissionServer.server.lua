-- SubmissionServer.lua
-- Players submit outfit for the current round.

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")
local submissionZone = workspace:WaitForChild("submissionZone")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))
local GameStateManager = require(GameLoop:WaitForChild("GameStateManager"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion
local scope = Fusion:scoped()
local OnEvent = Fusion.OnEvent

-- Instances
local SubmissionPad = submissionZone:WaitForChild("SubmissionPad")
local promptHolder = SubmissionPad:WaitForChild("PromptHolder")

--

local function onOutfitSubmitted(player: Player)
    -- Only allow submissions during Dressing phase
    if GameStateManager.getCurrentState() ~= "Dressing" then
		warn("Game is not in dressing state.")
        return
    end

    -- Check if already submitted this round
    if GameOutfitManager.hasSubmitted(player.UserId) then
		warn("Player has already submitted.")
        return
    end

    -- Get humanoid description
    local humanoidDescription = getHumanoidDescriptionFromPlayer(player)
    if not humanoidDescription then
        warn("No Humanoid Description when submitting for player", player.Name)
        return
    end

    GameOutfitManager.submitOutfit(player, humanoidDescription)
end

local prompt = scope:New "ProximityPrompt" {
    Name = "SubmissionPrompt",
    Parent = promptHolder,
    Enabled = true,
    ActionText = "Submit Outfit",
    HoldDuration = 0.5,
    RequiresLineOfSight = false,
    MaxActivationDistance = 16,
    [OnEvent "Triggered"] = function(player)
        onOutfitSubmitted(player)
    end
}