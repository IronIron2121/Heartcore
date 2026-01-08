-- SubmissionServer.lua 
-- Players submit outfit for the CURRENT SUBMISSION contest.

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DailyChallenges = ServerScriptService:WaitForChild("DailyChallenges")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local submissionZone = workspace:WaitForChild("submissionZone")
local Data = ServerScriptService:WaitForChild("Data")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")
local SubmissionResultRF = Remotes:WaitForChild("SubmissionResultRF")
local RolloverSubStore = Remotes:WaitForChild("RolloverSubStore")
local PhaseChanged = Bindables:WaitForChild("PhaseChanged") 

-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local DataManager = require(Data:WaitForChild("DataManager"))
local Fusion = require(Utility:WaitForChild("Fusion"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local ChallengeManager = require(DailyChallenges:WaitForChild("ChallengeManager"))

-- Instances
local SubmissionPad = submissionZone:WaitForChild("SubmissionPad")

-- Fusion
local scope = Fusion:scoped()
local OnEvent = Fusion.OnEvent

local promptHolder = SubmissionPad:WaitForChild("PromptHolder")
local promptEnabled = scope:Value(true)

local function onPhaseTransition()
	SubmissionStoreManager.onPhaseTransition()
end

local function canPlayerSubmit(player: Player)
	local lastSubmit = DataManager.GetLastOutfitSubmittedTime(player)
	if not lastSubmit or lastSubmit == 0 then
		return true
	end

	local success, currentPhaseStart = callWithRetry(
		function()
			return GameTimer.getCurrentPhaseUnixTime()
		end,
		5
	)

	if not currentPhaseStart then
		SubmissionResultRE:FireClient(player, {
			ok = false,
			msg = Constants.NO_CURRENT_PHASE_MESSAGE
		})
		
		return false
	end

	if not success or lastSubmit >= currentPhaseStart then
		warn("no, they can't submit")
		return false
	end

	return true
end
 
local function onOutfitSubmitted(player: Player)
	if not canPlayerSubmit(player) then
		SubmissionResultRE:FireClient(player, {
			ok = false, 
			msg = "You've already submitted this phase. Try again tomorrow!"
		})

		warn("can't submit rn!!!")
		return 
	end


	-- Get humanoid description
	local humanoidDescription = getHumanoidDescriptionFromPlayer(player)
	if not humanoidDescription then
		warn("No Humanoid Description when submitting for player", player.Name)
		SubmissionResultRE:FireClient(player, {
			ok=false, 
			msg = "humanoidDescription not loaded"}
		)
		return
	end

	-- Serialise it
	local serialisedHumanoidDescription = SerialisationService.SerialiseHumanoidDescription(humanoidDescription)
	local success = SubmissionStoreManager:AddEntryToStore(player, serialisedHumanoidDescription)
	
	if not success then return end

	DataManager.AddExp(player, 1)
	ChallengeManager.OnOutfitSubmitted(player)
	DataManager.onOutfitSubmitted(player)
end

local prompt = scope:New "ProximityPrompt" {
	Name = "SubmissionPrompt",
	Parent = promptHolder,
	Enabled = promptEnabled,
	ActionText = "Submit Outfit", 
	HoldDuration = 0.5,
	RequiresLineOfSight = false,
	MaxActivationDistance = 16,
	[OnEvent "Triggered"] = function(player)
		onOutfitSubmitted(player)
	end
}

--

SubmissionResultRF.OnServerInvoke = canPlayerSubmit
PhaseChanged.Event:Connect(onPhaseTransition)
RolloverSubStore.OnServerEvent:Connect(function(player)
	SubmissionStoreManager.incrementIndex()
end)