--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local votingZone = workspace:WaitForChild("votingZone")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")

-- Instances
local VotingPad = votingZone:WaitForChild("VotingPad")
local promptHolder = VotingPad:WaitForChild("PromptHolder")

-- Modules
local VotingGuiController = require(FusionComponents:WaitForChild("VotingGuiController"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Remotes / Bindables
local LocalTimerUpdated = Bindables:WaitForChild("LocalTimerUpdated")

-- Fusion Modules
local scope = Fusion:scoped()
local peek = Fusion.peek
local OnEvent = Fusion.OnEvent

-- Variables
local VoteGuiVisible = scope:Value(false)
local TimeText = scope:Value("Loading...")

-- 

local function onVotePromptActivated()
    if peek(VoteGuiVisible) == true then
        VoteGuiVisible:set(false)
    else
        VoteGuiVisible:set(true)
        VotingGuiController.refreshOutfits()
    end
end

local function updateTimeText(newText: string)
    TimeText:set(newText)
end

local function initialiseVoteGui()
    local _VotePrompt = scope:New "ProximityPrompt" {
        Parent = promptHolder,
        MaxActivationDistance = 20,
        RequiresLineOfSight = false,
        ActionText = "Vote Here!",

        [OnEvent "Triggered"] = function()
            onVotePromptActivated()
        end
    }

    VotingGuiController.Initialise(VoteGuiVisible, TimeText)
end 



initialiseVoteGui()

LocalTimerUpdated.Event:Connect(updateTimeText)