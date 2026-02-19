--!strict
-- WinnersManager.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local dailyWinners = workspace:WaitForChild("dailyWinners")
local descriptions = ReplicatedStorage:WaitForChild("Descriptions")
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")
local Values = ReplicatedStorage.Values

-- Modules
local ExpConfig = require(ReplicatedStorage.Libraries.ExpConfig)
local callWithRetry = require(ReplicatedStorage.Utility.callWithRetry)
local DataManager = require(ServerScriptService.Data.DataManager)
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))
local ChallengeManager = require(ServerScriptService:WaitForChild("DailyChallenges"):WaitForChild("ChallengeManager"))

-- Replicated Values
local CurrentThemeName = Values:WaitForChild("CurrentThemeName") :: StringValue 

-- Instances
local leaderboard = dailyWinners:WaitForChild("leaderboard")
local leaderboardScreen = leaderboard:WaitForChild("leaderboardScreen")
local WinnersThemeGui = leaderboardScreen:WaitForChild("WinnersThemeGui")
local WinnersThemeFrame = WinnersThemeGui:WaitForChild("WinnersThemeFrame")
local ThemeLabel = WinnersThemeFrame:WaitForChild("ThemeLabel")
local defaultWinnerDescription = descriptions:WaitForChild("DefaultWinner")

local leaderboardGui = leaderboardScreen:WaitForChild("LeaderboardGui")
local leaderboardFrame = leaderboardGui:WaitForChild("LeaderboardFrame")

-- Constants
local winnersRigScale = 3.547

-- Types
type RigModel = Model & {
	Humanoid: Humanoid
}

local podiumRigs = {
	[1] = dailyWinners:WaitForChild("FirstPlace") :: RigModel,
	[2] = dailyWinners:WaitForChild("SecondPlace") :: RigModel,
	[3] = dailyWinners:WaitForChild("ThirdPlace") :: RigModel,
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

	warn("Rankings: ", rankings)

	for i = 1, count do
		local outfit = rankings[i]

		local success, playerName = pcall(function()
			return Players:GetNameFromUserIdAsync(outfit.userId)
		end)

		-- Format score as percentage
		--local scorePercent = math.floor(outfit.score * 100 + 0.5)
		local displayName = if success then playerName else "Player " .. tostring(i)
		
		local newLabel = Instance.new("TextLabel")
		newLabel.Parent = leaderboardFrame
		newLabel.LayoutOrder = i
		newLabel.Text = string.format("%d. %s", i, displayName)
		newLabel.Size = UDim2.new(1, 0, 0, 30)
		newLabel.BackgroundTransparency = 1
		newLabel.TextColor3 = Color3.fromRGB(92, 96, 214)
		newLabel.TextSize = 75
		newLabel.Font = Enum.Font.GothamBold
	end

	ThemeLabel.Text = CurrentThemeName.Value
end

function WinnersManager.setNewWinners()
	local rankings = GameOutfitManager.getOutfitsByScore()

	if #rankings == 0 then
		return false
	end

	local top3 = {}
	for i = 1, math.min(3, #rankings) do
		local submission = rankings[i]
		table.insert(top3, submission)
		task.spawn(function()
			local success, player = callWithRetry(function()  
				return Players:GetPlayerByUserId(submission.userId)
			end)
			if not success or not player then return end
			if i <= 3 then
				DataManager.AddExp(player, ExpConfig.Placements[i])
			elseif i <= 20 then
				DataManager.AddExp(player, ExpConfig.Rewards.TOP_20) 
			end
		end)
	end

	-- Increment top 20 challenge for all ranked players in the top 20
	for i = 1, math.min(20, #rankings) do
		local submission = rankings[i]
		task.spawn(function()
			local success, player = callWithRetry(function()
				return Players:GetPlayerByUserId(submission.userId)
			end)
			if success and player then
				ChallengeManager.OnPlacedTop20(player)
			end
		end)
	end

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