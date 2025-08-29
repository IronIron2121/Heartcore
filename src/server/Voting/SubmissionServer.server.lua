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

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Modules
local getHumanoidDescriptionFromPlayer = require(Getters:WaitForChild("getHumanoidDescriptionFromPlayer"))
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))

-- Prompt
local SubmitBooth = workspace:WaitForChild("SubmitBooth")
local promptHolder = SubmitBooth:WaitForChild("PromptHolder")
local prompt = promptHolder:FindFirstChildOfClass("ProximityPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt", promptHolder)
	prompt.ActionText = "Submit Outfit"
	prompt.HoldDuration = 0.5
end

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

Remotes.ClientPrintSubmissions.OnServerEvent:Connect(function()
	local CurrentSubmissionsMemoryStore = SubmissionStoreManager.getCurrentSubmissionMemoryStore()
	local pages = CurrentSubmissionsMemoryStore:ListItemsAsync(20)
end)