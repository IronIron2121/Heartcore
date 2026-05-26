--!strict
-- WinnersManager.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local descriptions = ReplicatedStorage:WaitForChild("Descriptions")
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")
local Values = ReplicatedStorage.Values

-- Models
local IntermissionZone = workspace:WaitForChild("INTERMISSION_ZONE")
local winnerRigs = IntermissionZone:WaitForChild("winnerRigs")

-- Modules
local ExpConfig = require(ReplicatedStorage.Libraries.ExpConfig)
local callWithRetry = require(ReplicatedStorage.Utility.callWithRetry)
local DataManager = require(ServerScriptService.Data.DataManager)
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))
local ChallengeManager = require(ServerScriptService:WaitForChild("DailyChallenges"):WaitForChild("ChallengeManager"))
local ChallengeDefinitions = require(ServerScriptService:WaitForChild("DailyChallenges"):WaitForChild("ChallengeDefinitions"))
local RoundXpTracker = require(GameLoop:WaitForChild("RoundXpTracker"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundSummaryRE = Remotes:FindFirstChild("RoundSummaryRE") or Instance.new("RemoteEvent")
RoundSummaryRE.Name = "RoundSummaryRE"
RoundSummaryRE.Parent = Remotes

-- Replicated Values
local CurrentThemeName = Values:WaitForChild("CurrentThemeName") :: StringValue 

-- Instances
local leaderboard = IntermissionZone:WaitForChild("leaderboard")
local leaderboardScreen = leaderboard:WaitForChild("leaderboardScreen")
local WinnersThemeGui = leaderboardScreen:WaitForChild("WinnersThemeGui")
local WinnersThemeFrame = WinnersThemeGui:WaitForChild("WinnersThemeFrame")
local ThemeLabel = WinnersThemeFrame:WaitForChild("ThemeLabel")
local defaultWinnerDescription = descriptions:WaitForChild("DefaultWinner")

local leaderboardGui = leaderboardScreen:WaitForChild("LeaderboardGui")
local leaderboardFrame = leaderboardGui:WaitForChild("LeaderboardFrame")

-- Constants
local winnersRigScale = 1

-- Types
type RigModel = Model & {
	Humanoid: Humanoid
}

local podiumRigs = {
	[1] = winnerRigs:WaitForChild("FirstPlace") :: RigModel,
	[2] = winnerRigs:WaitForChild("SecondPlace") :: RigModel,
	[3] = winnerRigs:WaitForChild("ThirdPlace") :: RigModel,
}

local defaultWinnerIds = {
	156,
	5226107848,
	7356280958,
}

--

local WinnersManager = {}

local function resetRig(rig: RigModel, index: number?)
	rig:ScaleTo(1)
	local description
	if index then
		description = defaultWinnerDescription
	else
		description = defaultWinnerDescription
	end
	rig.Humanoid:ApplyDescriptionResetAsync(description)
	rig:ScaleTo(winnersRigScale)
end

local function resetPodiums()
	for index, rig in ipairs(podiumRigs) do
		resetRig(rig, index)
	end
end

local function resetLeaderboard()
	for _, child in ipairs(leaderboardFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function resetThemeLabel()
	ThemeLabel.Text = ""
end

function WinnersManager.reset()
	resetPodiums()
	resetLeaderboard()
	resetThemeLabel()
end
 
function WinnersManager.updatePodiums(winners: { GameOutfitManager.Outfit })
	for index, outfit in ipairs(winners) do
		local rig = podiumRigs[index]
		if not rig then continue end

		rig:SetAttribute("outfitId", outfit.outfitId)

		local success = pcall(function()
			rig:ScaleTo(1)
			rig.Humanoid:ApplyDescriptionResetAsync(outfit.humanoidDescription)
			rig:ScaleTo(winnersRigScale)
		end)

		if not success then
			warn("Failed to apply description to rig at index:", index)
			resetRig(rig)
		end
	end
end

function WinnersManager.updateLeaderboard(rankings: { GameOutfitManager.Outfit })
	resetLeaderboard()

	local count = math.min(20, #rankings)

	print("Rankings: ", rankings)

	for i = 1, count do
		local outfit = rankings[i]

		local success, playerName = pcall(function()
			return Players:GetNameFromUserIdAsync(outfit.userId)
		end)

		-- Format score as percentage
		local scorePercent = math.floor(outfit.score * 100 + 0.5)
		local displayName = if success then playerName else "Player " .. tostring(i)
		
		local newLabel = Instance.new("TextLabel")
		newLabel.Parent = leaderboardFrame
		newLabel.LayoutOrder = i
		newLabel.Text = string.format("%d. %s (%d%%)", i, displayName, scorePercent)
		newLabel.Size = UDim2.new(1, 0, 0, 30)
		newLabel.BackgroundTransparency = 1
		newLabel.TextColor3 = Color3.fromRGB(92, 96, 214)
		newLabel.TextSize = 75
		newLabel.Font = Enum.Font.GothamBold
	end

	ThemeLabel.Text = CurrentThemeName.Value
end

local PLACEMENT_LABELS = { "1ST PLACE", "2ND PLACE", "3RD PLACE" }

function WinnersManager.setNewWinners()
	local rankings = GameOutfitManager.getOutfitsByScore()

	if #rankings == 0 then
		return false
	end

	-- Build userId → placement index for all ranked players
	local placementByUser: { [number]: number } = {}
	for i, submission in ipairs(rankings) do
		placementByUser[submission.userId] = i
	end

	-- Accumulate placement XP and update top-20 challenge
	local top3 = {}
	for i = 1, math.min(#rankings, 20) do
		local submission = rankings[i]
		if i <= 3 then
			table.insert(top3, submission)
			RoundXpTracker.accumulate(submission.userId, ExpConfig.Placements[i], PLACEMENT_LABELS[i])
		else
			RoundXpTracker.accumulate(submission.userId, ExpConfig.Rewards.TOP_20, "TOP 20")
		end
		task.spawn(function()
			local success, player = callWithRetry(function()
				return Players:GetPlayerByUserId(submission.userId)
			end)
			if success and player then
				ChallengeManager.OnPlacedTop20(player)
			end
		end)
	end

	-- Fire round summary to every player, then apply accumulated XP
	local allPlayers = Players:GetPlayers()
	local challengeDefs = ChallengeDefinitions.GetDailyChallengeSet()

	for _, player in allPlayers do
		local record = RoundXpTracker.getForPlayer(player.UserId)
		local previousExp = (player:FindFirstChild("leaderstats") :: Folder?)
			and (player.leaderstats:FindFirstChild("Exp") :: NumberValue?)
			and player.leaderstats.Exp.Value
			or 0

		local challenges = {}
		for _, def in ipairs(challengeDefs) do
			table.insert(challenges, {
				id = def.id,
				label = def.name,
				progress = ChallengeManager.getChallengeProgress(player, def.id),
				target = def.targetAmount,
				xpReward = def.reward.exp,
			})
		end

		RoundSummaryRE:FireClient(player, {
			placement   = placementByUser[player.UserId],
			previousExp = previousExp,
			xpBreakdown = record and record.breakdown or {},
			totalXp     = record and record.total or 0,
			challenges  = challenges,
		})
	end

	RoundXpTracker.applyAll(allPlayers)

	GameOutfitManager.setPodiumOutfits(top3)

	local podiumSuccess = pcall(function()
		WinnersManager.updatePodiums(top3)
	end)

	local leaderboardSuccess = pcall(function()
		WinnersManager.updateLeaderboard(rankings)
	end)

	if not podiumSuccess or not leaderboardSuccess then
		warn("Failed to update winners displays — resetting")
		WinnersManager.reset()
		return false
	end

	return true
end

function WinnersManager.initialise()
	WinnersManager.reset()
end

return WinnersManager