-- GameStateManager.lua

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Values = ReplicatedStorage:WaitForChild("Values")


-- Modules
local WinnersManager = require(ServerScriptService.Voting.WinnersManager)
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))

--

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

Players.PlayerAdded:Connect(function(player)
	participatingPlayers[player.UserId] = true
end)

Players.PlayerRemoving:Connect(function(player)
	participatingPlayers[player.UserId] = nil
	finishedVotingPlayers[player.UserId] = nil
	GameStateManager._checkHurry()
end)

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
	print("All players have finished voting!")

	GameStateManager.hurryRound()
end 

function GameStateManager.markFinishedVoting(player: Player)
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

function GameStateManager._onStateEnter(stateName: string)
	if stateName == "Dressing" then
		-- Select new theme
		currentTheme = selectNewTheme()
		currentThemeName.Value = currentTheme
		
		GameOutfitManager.reset()
	elseif stateName == "Voting" then
		finishedVotingPlayers = {}
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
	GameStateManager.transitionTo("Dressing")
end

return GameStateManager