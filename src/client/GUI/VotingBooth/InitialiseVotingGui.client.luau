--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")


-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local votingZone = workspace:WaitForChild("votingZone")
local centralPond = workspace:WaitForChild("centralPond")

-- Instances
local VotingPad = votingZone:WaitForChild("VotingPad")
local promptHolder = VotingPad:WaitForChild("PromptHolder")
local pondModel = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = pondModel:WaitForChild("SubmissionBillboardHolder")
local BillboardGui = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame = BillboardGui:WaitForChild("Frame")
local TimeLabel = Frame:WaitForChild("TimeLabel")

-- Modules
local VotingGuiController = require(FusionComponents:WaitForChild("VotingGuiController"))
--local VotingClientManager = require(Utility:WaitForChild("VotingClientManager"))
local Fusion = require(Utility:WaitForChild("Fusion"))


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
            warn("triggering!")
            onVotePromptActivated()
        end
    }

    task.spawn(function()
        while true do
            task.wait(1)
            updateTimeText(TimeLabel.Text)
			--VotingClientManager.updateTimeText(TimeLabel.Text)
        end
    end)

    VotingGuiController.Initialise(VoteGuiVisible, TimeText)
	--VotingClientManager.initialiseVotingGui()
end 

initialiseVoteGui()