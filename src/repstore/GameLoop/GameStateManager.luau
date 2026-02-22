-- GameStateManager.lua

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local GeneralWorld = workspace:WaitForChild("GeneralWorld")
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Values = ReplicatedStorage:WaitForChild("Values")


-- Modules
local GameStates = require(script.Parent.GameStates)
local Constants = require(ReplicatedStorage.Constants)
local randomTeleport = require(ReplicatedStorage:WaitForChild("Utility").randomTeleport)
local WinnersManager = require(ServerScriptService.Voting.WinnersManager)
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))

-- Spawn destinations
local STATE_SPAWNS = {
	Dressing = GeneralWorld.GameSpawn,
	Voting = GeneralWorld.VoteSpawn,
	Intermission = GeneralWorld.IntermissionSpawn,
}

local STATES = require(GameLoop.GameStates)

local THEMES = {
	"Y2K",
	"Cottagecore",
	"Streetwear",
	"Old Money",
	"Cyberpunk",
	"Festival Ready",
	"Office Siren",
	"Coastal Grandmother",
	"Dark Academia",
	"Barbiecore",
	"Grunge Revival",
	"Royalcore",
	"Athleisure",
	"Boho Chic",
	"Minimalist",
	"Retro 70s",
	"Punk Rock",
	"Fairycore",
	"Western",
	"Avant-Garde",
	"Cottagecore Witch",
	"Miami Vice",
	"Soft Goth",
	"Preppy",
	"Harajuku",
	"Glamour",
	"Space Age",
	"Mermaidcore",
	"Safari Chic",
	"Art Deco",
	"Vampire",
	"Pastel Goth",
	"Sporty Spice",
	"Regencycore",
	"Skater",
	"Tropical",
	"Steampunk",
	"Cottagecore Princess",
	"Neon Rave",
	"Military Chic",
	"Coquette",
	"Indie Sleaze",
	"Ballet Core",
	"Pirate",
	"Mob Wife",
	"Clean Girl",
	"Big Pharma",
	"Gothic Romance",
	"Ski Lodge",
	"Prom Night",
	"Shoegaze Dream",
	"Motown Glam",
	"Riot Grrrl",
	"Lo-Fi Bedroom",
	"Studio 54",
	"Synth Wave",
	"Nashville Glitter",
	"Bossa Nova",
	"Post-Punk",
	"Neo-Soul",
	"Hyperpop",
	"Woodstock",
	"Afrobeats",
	"Cabaret",
	"Underground Rave",
	"Britpop",
	"Juke Joint",
	"City Pop",
	"Glam",
	"Unplugged",
}

local MAX_RECENT_THEMES = 5
local MIN_PLAYERS = 3

local currentState: string = nil
local currentTheme: string = nil

local recentThemes: { string } = {}
local participatingPlayers: {[number]: boolean} = {}
local finishedVotingPlayers: {[number]: boolean} = {}

local currentStateName = Values:FindFirstChild("CurrentStateName") or Instance.new("StringValue")
currentStateName.Name = "CurrentStateName"
currentStateName.Parent = Values

local currentThemeName = Values:FindFirstChild("CurrentThemeName") or Instance.new("StringValue")
currentThemeName.Name = "CurrentThemeName"
currentThemeName.Parent = Values

local secondsRemaining = Values:FindFirstChild("SecondsRemaining") or Instance.new("IntValue")
secondsRemaining.Name = "SecondsRemaining"
secondsRemaining.Parent = Values

--

local GameStateManager = {}

-- Participation remote
local SetParticipatingRE = Remotes:FindFirstChild("SetParticipating") or Instance.new("RemoteEvent")
SetParticipatingRE.Name = "SetParticipating"
SetParticipatingRE.Parent = Remotes

SetParticipatingRE.OnServerEvent:Connect(function(player, participating)
	if participating then
		participatingPlayers[player.UserId] = true
	else
		participatingPlayers[player.UserId] = nil
		finishedVotingPlayers[player.UserId] = nil
		GameStateManager._checkHurry()
	end
end)

local function getPlayerCount(): number
	local count = 0
	for _ in participatingPlayers do
		count += 1
	end
	return count
end

Players.PlayerAdded:Connect(function(player)
	participatingPlayers[player.UserId] = true

	if currentState == "Waiting" then
		task.spawn(randomTeleport, player, STATE_SPAWNS.Intermission)
		if getPlayerCount() >= MIN_PLAYERS then
			GameStateManager.transitionTo("Dressing")
		end
	elseif currentState then
		task.spawn(randomTeleport, player, STATE_SPAWNS[currentState])
	end
end)

Players.PlayerRemoving:Connect(function(player)
	participatingPlayers[player.UserId] = nil
	finishedVotingPlayers[player.UserId] = nil
	GameStateManager._checkHurry()
end)

local function teleportAllPlayers(destination: BasePart)
	for _, player in Players:GetPlayers() do
		task.spawn(randomTeleport, player, destination)
	end
end

local function selectNewTheme(): string
	local availableThemes = {}
	
	for _, theme in ipairs(THEMES) do
		if not table.find(recentThemes, theme) then
			table.insert(availableThemes, theme)
		end
	end
	
	-- Fallback if somehow all themes are recent (shouldn't happen with 20 themes and 5 recent)
	if #availableThemes == 0 then
		availableThemes = THEMES
	end
	
	local selectedTheme = availableThemes[math.random(1, #availableThemes)]
	
	-- Add to recent themes
	table.insert(recentThemes, selectedTheme)
	
	-- Trim to max recent
	if #recentThemes > MAX_RECENT_THEMES then
		table.remove(recentThemes, 1)
	end
	
	return selectedTheme
end

function GameStateManager._checkHurry()
	if currentState == "Dressing" then
		GameStateManager.checkAllSubmitted()
	elseif currentState == "Voting" then
		GameStateManager.checkAllFinishedVoting()
	end
end

function GameStateManager.checkAllSubmitted()
	if currentState ~= "Dressing" then return end

	local hasParticipants = false
	for userId in participatingPlayers do
		hasParticipants = true
		if not GameOutfitManager.hasSubmitted(userId) then
			return
		end
	end

	if not hasParticipants then 
		return 
	end

	GameStateManager.hurryRound()
end

function GameStateManager.checkAllFinishedVoting()
	if currentState ~= "Voting" then 
		return 
	end

	local hasParticipants = false

	for userId in participatingPlayers do
		hasParticipants = true
		if not finishedVotingPlayers[userId] then
			return
		end
	end

	if not hasParticipants then 
		print("No participants at checkAllFinishedVoting") 
		return
	end

	print("All players have finished voting!", participatingPlayers)

	GameStateManager.hurryRound()
end 

function GameStateManager.markFinishedVoting(player: Player)
	warn("Marking finished voting")
	finishedVotingPlayers[player.UserId] = true
	GameStateManager.checkAllFinishedVoting()
end

function GameStateManager.hurryRound()
	task.defer(
		function()
			if secondsRemaining.Value >= 10 then
				secondsRemaining.Value = 10
			end
		end
	)
end

local function startCountdown(duration: number)
	secondsRemaining.Value = duration
	
	timerThread = task.spawn(function()
		while secondsRemaining.Value > 0 do
			task.wait(1)
			task.defer(function()
				secondsRemaining.Value -= 1
			end)
		end
		GameStateManager.transitionTo(STATES[currentState].next)
	end)
end

function GameStateManager.transitionTo(stateName: string)
	local config = STATES[stateName]
	timerThread = nil

	currentState = stateName
	currentStateName.Value = stateName

	GameStateManager._onStateEnter(stateName)
	startCountdown(config.duration)
end

-- Optional callback set by VotingArenaManager to handle Voting-phase teleportation.
-- When set, it is called instead of teleportAllPlayers for the Voting state.
GameStateManager.onVotingStart = nil :: (() -> ())?

function GameStateManager._onStateEnter(stateName: string)
	-- For Voting, onVotingStart handles teleportation; skip the generic teleport
	if stateName ~= "Voting" or not GameStateManager.onVotingStart then
		teleportAllPlayers(STATE_SPAWNS[stateName])
	end

	if stateName == "Dressing" then
		-- Select new theme
		currentTheme = selectNewTheme()
		currentThemeName.Value = currentTheme

		GameOutfitManager.reset()
	elseif stateName == "Voting" then
		-- Auto-submit for players who didn't submit during Dressing
		for userId in participatingPlayers do
			if not GameOutfitManager.hasSubmitted(userId) then
				local player = Players:GetPlayerByUserId(userId)
				if player and player.Character then
					local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						GameOutfitManager.submitOutfit(player, humanoid:GetAppliedDescription())
					end
				end
			end
		end
		finishedVotingPlayers = {}
		-- Kick off the arena after all auto-submissions are complete
		if GameStateManager.onVotingStart then
			GameStateManager.onVotingStart()
		end
	elseif stateName == "Intermission" then
		WinnersManager.reset()
		WinnersManager.setNewWinners()
	end
end

function GameStateManager.getCurrentState(): string
	return currentState
end

function GameStateManager.getCurrentTheme(): string
	return currentTheme
end

function GameStateManager.getSecondsRemaining(): number
	return secondsRemaining.Value
end

function GameStateManager.start()
	if getPlayerCount() >= MIN_PLAYERS or Constants.DEBUG_MODE == true then
		GameStateManager.transitionTo(GameStates.Intermission.name)
	else
		currentState = "Waiting"
		currentStateName.Value = "Waiting"
		currentThemeName.Value = ""
		secondsRemaining.Value = 0
		teleportAllPlayers(STATE_SPAWNS.Intermission)
	end
end

return GameStateManager