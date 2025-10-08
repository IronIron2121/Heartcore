-- SubmissionServer.lua 
-- Players submit outfit for the CURRENT SUBMISSION contest.

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")
local Getters = ReplicatedStorage:WaitForChild("Getters")
local centralPond = workspace:WaitForChild("centralPond")
local Data = ServerScriptService:WaitForChild("Data")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")
local SubmissionResultRF = Remotes:WaitForChild("SubmissionResultRF")
local PhaseChanged = Bindables:WaitForChild("PhaseChanged") 

local SubmissionResultRF = Remotes:WaitForChild("SubmissionResultRF")
local PhaseChanged = Bindables:WaitForChild("PhaseChanged") 


-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local DataManager = require(Data:WaitForChild("DataManager"))
local Fusion = require(Utility:WaitForChild("Fusion"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))
local GameTimer = require(Voting:WaitForChild("GameTimer"))

-- Instances
local SubmissionPad = centralPond:WaitForChild("SubmissionPad") 
local SubmissionPad = centralPond:WaitForChild("SubmissionPad") 

-- Fusion
local scope = Fusion:scoped()
local peek = Fusion.peek
local peek = Fusion.peek
local OnEvent = Fusion.OnEvent

local promptHolder = SubmissionPad:WaitForChild("PromptHolder")
local promptEnabled = scope:Value(true)
local isSubmitting = scope:Value(false)

local function canPlayerSubmit(player: Player)
	local lastSubmit = DataManager.GetLastOutfitSubmittedTime(player)
	if not lastSubmit or lastSubmit == 0 then
		warn("no previous submission")
		return true
	end

	local currentPhaseStart = GameTimer.getCurrentPhaseUnixTime()

	if lastSubmit >= currentPhaseStart then
		warn("no, they can't submit")
		return false
	end

	warn("yes, they can submit")
	return true
end

local isSubmitting = scope:Value(false)

local function canPlayerSubmit(player: Player)
	local lastSubmit = DataManager.GetLastOutfitSubmittedTime(player)
	if not lastSubmit or lastSubmit == 0 then
		warn("no previous submission")
		return true
	end

	local currentPhaseStart = GameTimer.getCurrentPhaseUnixTime()

	if lastSubmit >= currentPhaseStart then
		warn("no, they can't submit")
		return false
	end

	warn("yes, they can submit")
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
		warn("No Humanoid Description")
		SubmissionResultRE:FireClient(player, {ok=false, msg = "humanoidDescription not loaded"})
		return
	end

	-- Serialise it
	local serialisedHumanoidDescription = SerialisationService.SerialiseHumanoidDescription(humanoidDescription)

	local success = SubmissionStoreManager:AddEntryToStore(player, serialisedHumanoidDescription)
	
	if not success then return end

	DataManager.AddExp(player, 1)
	DataManager.onOutfitSubmitted(player)	
	SubmissionResultRE:FireClient(player, {ok=true, msg = "Outfit submitted successfully!"})
end


local prompt = scope:New "ProximityPrompt" {
	Name = "SubmissionPrompt",
	Name = "SubmissionPrompt",
	Parent = promptHolder,
	Enabled = promptEnabled,
	ActionText = "Submit Outfit", 
	ActionText = "Submit Outfit", 
	HoldDuration = 0.5,
	RequiresLineOfSight = false,
	MaxActivationDistance = 16,
	[OnEvent "Triggered"] = function(player)
		if peek(isSubmitting) then
			return
		end
		isSubmitting:set(true)
		if peek(isSubmitting) then
			return
		end
		isSubmitting:set(true)
		onOutfitSubmitted(player)
		isSubmitting:set(false)
		isSubmitting:set(false)
	end
}

SubmissionResultRF.OnServerInvoke = canPlayerSubmit