-- ThemeManager.lua
-- Manages staggered contests: one submission & one voting active.

--[[
local DataStoreService = game:GetService("DataStoreService")
local ThemeStore = DataStoreService:GetDataStore("StaggeredContests_v1")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ContestUpdatedRE = Remotes:WaitForChild("ContestUpdated")

local ContestManager = require(game.ServerScriptService:WaitForChild("ContestManager"))

local Themes = {
	"Cyberpunk Streetwear","Medieval Knight","Beach Party","Winter Wonderland",
	"Space Explorer","Royal Ball","Sports Day"
}
local function pickTheme() return Themes[math.random(1,#Themes)] end


--local PHASE_SECONDS = 24 * 60 * 60   <- 1day
local PHASE_SECONDS = 60 -- For quick testing

local contests = nil

local function save()
	pcall(function() ThemeStore:SetAsync("contests_v1", contests) end)
end

local function loadOrInitialise()
	local success, data = pcall(function() return ThemeStore:GetAsync("contests_v1") end)
	if success and data then
		contests = data
	else
		local now = os.time()
		contests = {
			CurrentSubmission = { theme = pickTheme(), start = now, id = tostring(now), entries = {} },
			CurrentVoting     = { theme = pickTheme(), start = now, id = tostring(now+1), entries = {}, votes = {} },
			LastShift = now
		}
		save()
	end
	ContestUpdatedRE:FireAllClients(contests)
end

local function shiftIfNeeded()
	local now = os.time()
	if now - (contests.LastShift or 0) >= PHASE_SECONDS then
		-- finalize voting
		if contests.CurrentVoting then
			pcall(function() ContestManager:FinalizeVoting(contests.CurrentVoting) end)
		end
		-- promote submission -> voting
		contests.CurrentVoting = {
			theme = contests.CurrentSubmission.theme, start = now, id = tostring(now),
			entries = contests.CurrentSubmission.entries, votes = {}
		}
		-- new submission
		contests.CurrentSubmission = { theme = pickTheme(), start = now, id = tostring(now+1), entries = {} }
		contests.LastShift = now
		save()
		ContestUpdatedRE:FireAllClients(contests)
	end
end

loadOrInitialise()

task.spawn(function()
	while true do
		shiftIfNeeded()
		task.wait(30)
	end
end)

]]