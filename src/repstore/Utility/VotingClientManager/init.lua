--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local VotingGuiController = require(FusionComponents:WaitForChild("VotingGuiController"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion setup
local scope = Fusion:scoped()
local peek = Fusion.peek

-- Reactive values shared across scripts
local VoteGuiVisible = scope:Value(false)
local TimeText = scope:Value("Loading...")

-- Main toggle function
local function onVotePromptActivated()
	if peek(VoteGuiVisible) == true then
		VoteGuiVisible:set(false)
	else
		VoteGuiVisible:set(true)
		VotingGuiController.refreshOutfits()
	end
end

-- Function to update the time label text
local function updateTimeText(newText: string)
	TimeText:set(newText)
end

-- Initialise GUI once
local function initialiseVotingGui()
	VotingGuiController.Initialise(VoteGuiVisible, TimeText)
end

-- Export everything for other scripts to use
return {
	onVotePromptActivated = onVotePromptActivated,
	updateTimeText = updateTimeText,
	initialiseVotingGui = initialiseVotingGui,
	VoteGuiVisible = VoteGuiVisible,
	TimeText = TimeText,
}
