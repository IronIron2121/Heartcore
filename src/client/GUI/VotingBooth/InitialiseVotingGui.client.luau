--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")

-- Instances
local votingBooth = workspace:WaitForChild("VotingBooth")
local promptHolder = votingBooth:WaitForChild("PromptHolder")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local VotingGuiController = require(FusionComponents:WaitForChild("VotingGuiController"))

-- Fusion Modules
local scope = Fusion:scoped()
local peek = Fusion.peek
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
    local _VotePrompt = scope:New "ProximityPrompt" {
        Parent = promptHolder,
        MaxActivationDistance = 20,
        ActionText = "Vote Here!",

        [OnEvent "Triggered"] = function()
            onVotePromptActivated()
        end
    }

    VotingGuiController.Initialise(VoteGuiVisible)

end

initialiseVoteGui()