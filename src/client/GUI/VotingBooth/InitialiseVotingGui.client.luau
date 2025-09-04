--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local votingZone = workspace:WaitForChild("votingZone")

-- Instances
local VotingPad = votingZone:WaitForChild("VotingPad")
local promptHolder = VotingPad:WaitForChild("PromptHolder")

-- Modules
local VotingGuiController = require(FusionComponents:WaitForChild("VotingGuiController"))

local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Remotes
local GetContestSubmissionsCache = Remotes:WaitForChild("GetContestSubmissionsCache")
local GetBalancedOutfit = Remotes:WaitForChild("GetBalancedOutfit")

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
        print(
            callWithRetry(function()
                return GetContestSubmissionsCache:InvokeServer()
            end)
        )
    end
end

local function initialiseVoteGui()
    local _VotePrompt = scope:New "ProximityPrompt" {
        Parent = promptHolder,
        MaxActivationDistance = 20,
        RequiresLineOfSight = false,
        ActionText = "Vote Here!",

        [OnEvent "Triggered"] = function()
            onVotePromptActivated()
            print(GetBalancedOutfit:InvokeServer())
        end
    }

    VotingGuiController.Initialise(VoteGuiVisible)

end

initialiseVoteGui()