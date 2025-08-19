--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Instances
local votingBooth = workspace:WaitForChild("VotingBooth")
local promptHolder = votingBooth:WaitForChild("PromptHolder")
local votePrompt = promptHolder:WaitForChild("VotePrompt")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion Modules
local scope = Fusion:scoped()
local peek = Fusion.peek

-- Variables
local VoteGuiVisible = scope:Value(false)

--

local function onVotePromptActivated()
    if peek(VoteGuiVisible) == true then
        VoteGuiVisible:set(false)
    else
        VoteGuiVisible:set(true)
    end
end

local function initialiseVoteGui()

end

initialiseVoteGui()

votePrompt.Triggered:Connect(onVotePromptActivated)