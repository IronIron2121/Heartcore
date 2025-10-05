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
local Data = ServerScriptService:WaitForChild("Data")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local DataManager = require(Data:WaitForChild("DataManager"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Instances
local SubmissionPad = centralPond:WaitForChild("SubmissionPad")

-- Fusion
local scope = Fusion:scoped()
local peek = Fusion.peek
local OnEvent = Fusion.OnEvent

local promptHolder = SubmissionPad:WaitForChild("PromptHolder")
local promptEnabled = scope:Value(true)
local isSubmitting = scope:Value(false)

-- Prompt
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

	SubmissionStoreManager:AddEntryToCache(player, serialisedHumanoidDescription)
	
	DataManager.AddExp(player, 1)
	
	task.spawn(function()
		promptEnabled:set(false)
		promptHolder.Color = Color3.fromRGB(100,100,100)
		task.wait(10)
		promptEnabled:set(true)		
		promptHolder.Color = Color3.fromRGB(163,162,165)
	end)
end

local function initialiseSubmissionFlushing()
	SubmissionStoreManager.startPeriodicFlush()
end

local prompt = scope:New "ProximityPrompt" {
	Parent = promptHolder,
	Enabled = promptEnabled,
	ActionText = "Submit Outfit", 
	HoldDuration = 0.5,
	RequiresLineOfSight = false,
	MaxActivationDistance = 16,
	[OnEvent "Triggered"] = function(player)
		if peek(isSubmitting) then
			return
		end
		isSubmitting:set(true)
		onOutfitSubmitted(player)
		isSubmitting:set(false)
	end
}

initialiseSubmissionFlushing()