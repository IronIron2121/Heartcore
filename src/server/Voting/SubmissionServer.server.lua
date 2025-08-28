-- SubmissionServer.lua 
-- Players submit outfit for the CURRENT SUBMISSION contest.

-- Services
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = ServerScriptService:WaitForChild("Voting")

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResultRE")

-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local callWithRetry = require(Utility:WaitForChild("callWithRetry"))
local SubmissionStoreManager = require(Voting:WaitForChild("SubmissionStoreManager"))

-- Memory Stores
local CurrentContestMemoryStore = MemoryStoreService:GetSortedMap(Constants.CURRENT_CONTEST_MEMORYSTORE_NAME)

local SubmitBooth = workspace:WaitForChild("SubmitBooth")
local promptHolder = SubmitBooth:WaitForChild("PromptHolder")
local prompt = promptHolder:FindFirstChildOfClass("ProximityPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt", promptHolder)
	prompt.ActionText = "Submit Outfit"
	prompt.HoldDuration = 0.5
end

local function printAllHashMapPages(hashPages: MemoryStoreHashMapPages)
	local currentPageNumber = 1
	local processedPages = {}

	while not hashPages.IsFinished do
		local page = hashPages:GetCurrentPage()
		print(#page)
		if #page > 0 then
			print(page)
		end
		hashPages:AdvanceToNextPageAsync()
		currentPageNumber += 1
	end
end

local function onOutfitSubmitted(player: Player)
	local CurrentSubmissionsMemoryStore = SubmissionStoreManager.getCurrentSubmissionsMemoryStore()
	-- Get the player character
	local char = player.Character or player.CharacterAdded:Wait()
	
	if not char then
		SubmissionResultRE:FireClient(player, {ok=false, msg="Character not loaded"})
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("No Humanoid")
		SubmissionResultRE:FireClient(player, {ok=false, msg = "Humanoid not loaded"})
		return
	end

	local humanoidDescription = humanoid:FindFirstChildOfClass("HumanoidDescription")
	local serialisedHumanoidDescription = SerialisationService.SerialiseHumanoidDescription(humanoidDescription)

	local success = callWithRetry(function()
		return CurrentSubmissionsMemoryStore:SetAsync(
			tostring(player.UserId),
			serialisedHumanoidDescription,
			86400
		)
	end, 5)

	if success then
		print("Successfully submitted outfit for player:", player.Name)

		task.spawn(function()
			local pages = CurrentSubmissionsMemoryStore:ListItemsAsync(1)
			printAllHashMapPages(pages)
		end)


		SubmissionResultRE:FireClient(player, {
			ok = true,
			msg = "Outfit submitted successfully!"
		})
	else
		warn("Failed to submit outfit for player:", player.Name)
		SubmissionResultRE:FireClient(player, {
			ok = false,
			msg = "Failed to submit outfit. Please try again."
		})
	end
end

prompt.Triggered:Connect(onOutfitSubmitted)

Remotes.ClientPrintSubmissions.OnServerEvent:Connect(function()
	local CurrentSubmissionsMemoryStore = SubmissionStoreManager.getCurrentSubmissionsMemoryStore()
	local pages = CurrentSubmissionsMemoryStore:ListItemsAsync(20)
	printAllHashMapPages(pages)

end)