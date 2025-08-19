--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Instances
local votingBooth = workspace:WaitForChild("VotingBooth")
local promptHolder = votingBooth:WaitForChild("PromptHolder")
local localPlayer = Players.LocalPlayer

-- GUI
local PlayerGui = localPlayer.PlayerGui

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion Modules
local scope = Fusion:scoped()
local peek = Fusion.peek
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

-- Variables
local VoteGuiVisible = scope:Value(false)


--

local function onVotePromptActivated()
    if peek(VoteGuiVisible) == true then
        VoteGuiVisible:set(false)
    else
        VoteGuiVisible:set(true)
    end

    warn(peek(VoteGuiVisible))
end

local function initialiseVoteGui()
    local VotePrompt = scope:New "ProximityPrompt" {
        Parent = promptHolder,
        MaxActivationDistance = 20,
        ActionText = "Vote Here!",

        [OnEvent "Triggered"] = function()
            onVotePromptActivated()
        end
    }

    local VoteGui = scope:New "ScreenGui" {
        Enabled = VoteGuiVisible,
        Parent = PlayerGui,

        [Children] = {
            scope:New "TextButton" {
                Size = UDim2.fromScale(1, 1)
            }
        }
    }
end

initialiseVoteGui()