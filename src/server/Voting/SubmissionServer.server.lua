-- SubmissionServer.lua
-- Players submit outfit for the CURRENT SUBMISSION contest.

-- Services
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Voting = 	ServerScriptService:WaitForChild("Voting")

-- Datastores
local ThemeStore = DataStoreService:GetDataStore("StaggeredContests_v1")

-- Modules
local SerialisationService = require(Utility:WaitForChild("SerialisationService"))
local EntryStore = require(Voting:WaitForChild("EntryStore"))

-- Remotes
local SubmissionResultRE = Remotes:WaitForChild("SubmissionResult")

EntryStore:Init(true)

local SubmitBooth = workspace:WaitForChild("SubmitBooth")
local promptHolder = SubmitBooth:WaitForChild("PromptHolder")
local prompt = promptHolder:FindFirstChildOfClass("ProximityPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt", promptHolder)
	prompt.ActionText = "Submit Outfit"; prompt.HoldDuration = 0.5
end

prompt.Triggered:Connect(function(player)
	-- Get the player character
	local char = player.Character; if not char then SubmissionResultRE:FireClient(player,{ok=false,msg="Character not loaded"}) return end
	local hum = char:FindFirstChildOfClass("Humanoid"); 
	
	if not hum then
		warn("No Humanoid") 
		SubmissionResultRE:FireClient(player,{ok=false,msg="No Humanoid"}) 
		return 
	end

	-- Get all of the contests that exist
	local okC, contests = pcall(function() 
		return ThemeStore:GetAsync("contests_v1") 
	end)
	
	-- Get the current submission contest
	local currentSubmission = okC and contests and contests.CurrentSubmission 
	if not currentSubmission then 
		warn("No current submission")
		SubmissionResultRE:FireClient(player, {
			ok = false,
			msg = "No submission contest"
		}) 
		return
	end

	local themeId = currentSubmission.id
	local desc = hum:GetAppliedDescription()
	local serialized = SerialisationService.SerialiseHumanoidDescription(desc)
	local entryId = tostring(player.UserId) -- one submission per player; change to unique ids if needed

	local okS, err = EntryStore:SubmitEntry(entryId, player.Name, serialized, themeId)
	if okS then
		pcall(function()
			ThemeStore:UpdateAsync("contests_v1", function(old)
				local c = old or contests
				if c and c.CurrentSubmission then
					c.CurrentSubmission.entries = c.CurrentSubmission.entries or {}
					for _,v in ipairs(c.CurrentSubmission.entries) do if v==entryId then return c end end
					table.insert(c.CurrentSubmission.entries, entryId)
				end
				print(c)
				return c
			end)
		end)
		print("successfully submitted")
		SubmissionResultRE:FireClient(player, {ok=true, msg="Submitted for "..(currentSubmission.theme or "theme")})
	else
		warn("Failed to submit")
		SubmissionResultRE:FireClient(player, {ok=false, msg="Failed: "..tostring(err)})
	end
end)