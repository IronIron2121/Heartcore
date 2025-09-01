-- SubmissionServer.lua 
-- Players submit outfit for the CURRENT SUBMISSION contest.

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local centralPond = workspace:WaitForChild("centralPond")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))

-- Instances
local SubmissionPad = centralPond:WaitForChild("SubmissionPad")

-- Prompt
local promptHolder = SubmissionPad:WaitForChild("PromptHolder")
local prompt = Instance.new("ProximityPrompt") :: ProximityPrompt
prompt.Parent = promptHolder
prompt.ActionText = "Submit Outfit"
prompt.HoldDuration = 0.5
prompt.RequiresLineOfSight = false
prompt.MaxActivationDistance = 16


--

local function onOutfitSubmitted(player: Player)
	-- Get humanoid description
	local humanoidDescription = getHumanoidDescriptionFromPlayer(player)
	if not humanoidDescription then
		warn("No Humanoid Description")
		SubmissionResultRE:FireClient(player, {ok=false, msg = "humanoidDescription not loaded"})
		return
	end

	-- Serialise it
	local serialisedHumanoidDescription = SerialisationService.SerialiseHumanoidDescription(humanoidDescription)
	SubmissionStoreManager:AddEntry(player, serialisedHumanoidDescription)
end

prompt.Triggered:Connect(onOutfitSubmitted)
