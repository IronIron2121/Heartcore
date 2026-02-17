--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local ExpConfig = require(Libraries.ExpConfig)
local UI_CONSTANTS = require(Utility.UI_CONSTANTS)

-- Display constants
local TEXT_LABEL_SIZE = UDim2.fromScale(1, 0.5)
local BILLBOARD_GUI_NAME = "PlayerDisplayBillboard"
local NAME_LABEL_NAME = "PlayerNameLabel"
local RANK_LABEL_NAME = "PlayerRankLabel"

--

local DataManager = {}
DataManager.Profiles = {}

-- Helper function to get the start of a day (midnight UTC) for a given timestamp
local function getDayStart(timestamp: number): number
	return math.floor(timestamp / 86400) * 86400
end

local function getCurrentDayStart(): number
	return getDayStart(DateTime.now().UnixTimestamp)
end

local function getYesterdayStart(): number
	return getCurrentDayStart() - 86400
end

function DataManager.AddExp(player: Player, amount: number)
	local profile = DataManager.Profiles[player]

	if not profile then
		return
	end

	local oldLevel = profile.Data.Level
	local oldRankName = profile.Data.Rank or ExpConfig.RankNames[1]

	profile.Data.Exp += amount

	local newLevel = ExpConfig.getLevelFromExp(profile.Data.Exp)
	local newRankTier = ExpConfig.getRankTier(newLevel)
	local newRankName = ExpConfig.RankNames[newRankTier]

	if newLevel > oldLevel then
		profile.Data.Level = newLevel
		profile.Data.LevelUpTime = DateTime.now().UnixTimestamp

		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Level") then
			player.leaderstats.Level.Value = newLevel
		end
	end

	if newRankName ~= oldRankName then
		profile.Data.Rank = newRankName

		if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Rank") then
			player.leaderstats.Rank.Value = newRankName
		end
	end

	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Exp") then
		player.leaderstats.Exp.Value = profile.Data.Exp
	end

	if (newLevel > oldLevel) or (newRankName ~= oldRankName) then
		--warn("Updating player display")
		DataManager.UpdatePlayerDisplay(player)
	else
		--warn(newLevel, oldLevel, newRankName, oldRankName)
	end
end

function DataManager.ResetPlayerLevel(player: Player)
	local profile = DataManager.Profiles[player]

	if not profile then
		return
	end

	profile.Data.Exp = 0
	profile.Data.Level = 1
	profile.Data.Rank = ExpConfig.RankNames[1]

	if player:FindFirstChild("leaderstats") then
		if player.leaderstats:FindFirstChild("Level") then
			player.leaderstats.Level.Value = 1
		end
		if player.leaderstats:FindFirstChild("Rank") then
			player.leaderstats.Rank.Value = ExpConfig.RankNames[1]
		end
		if player.leaderstats:FindFirstChild("Exp") then
			player.leaderstats.Exp.Value = 0
		end
	end
end

function DataManager.ProcessLogin(player: Player)
	local profile = DataManager.Profiles[player]

	if not profile then
		warn("No profile found for player:", player.Name)
		return
	end

	local currentTime = DateTime.now().UnixTimestamp
	local currentDayStart = getCurrentDayStart()
	local lastLoginDayStart = getDayStart(profile.Data.LastLoginTime or 0)
	local yesterdayStart = getYesterdayStart()

	if lastLoginDayStart == currentDayStart then
		return
	end

	profile.Data.LastLoginTime = currentTime

	if lastLoginDayStart == yesterdayStart then
		profile.Data.LoginStreak += 1
		local expBonus = 1 + (profile.Data.LoginStreak * 0.5)
		DataManager.AddExp(player, expBonus)
		print("Consecutive login! Day", profile.Data.LoginStreak, "- Bonus:", expBonus, "exp")
	elseif lastLoginDayStart < yesterdayStart then
		profile.Data.LoginStreak = 1
		DataManager.AddExp(player, 1)
		print("Streak reset. New streak day 1 - Bonus: 1 exp")
	else
		profile.Data.LoginStreak = 1
		DataManager.AddExp(player, 1)
		print("First login or same day - Streak: 1 - Bonus: 1 exp")
	end

	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Exp") then
		player.leaderstats.Exp.Value = profile.Data.Exp
	end
end

function DataManager.GetLoginStreak(player: Player): number
	local profile = DataManager.Profiles[player]
	if not profile then
		return 0
	end
	return profile.Data.LoginStreak or 0
end

function DataManager.GetLastLoginTime(player: Player): number
	local profile = DataManager.Profiles[player]
	if not profile then
		return 0
	end
	return profile.Data.LastLoginTime or 0
end

function DataManager.GetTimeSinceLastLogin(player: Player): number
	local lastLogin = DataManager.GetLastLoginTime(player)
	if lastLogin == 0 then
		return 0
	end
	return DateTime.now().UnixTimestamp - lastLogin
end

function DataManager.onOutfitSubmitted(player: Player)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end
	profile.Data.LastOutfitSubmittedTime = DateTime.now().UnixTimestamp
end

function DataManager.GetLastOutfitSubmittedTime(player: Player): number
	local profile = DataManager.Profiles[player]
	if not profile then
		return 0
	end
	return profile.Data.LastOutfitSubmittedTime
end

function DataManager.DebugSetLastLogin(player: Player, daysAgo: number)
	local profile = DataManager.Profiles[player]
	if not profile then
		return
	end

	local targetDay = getCurrentDayStart() - (daysAgo * 86400)
	profile.Data.LastLoginTime = targetDay
	print("Debug: Set", player.Name, "last login to", daysAgo, "days ago")
end

function DataManager.GetLevel(player: Player): number
	local profile = DataManager.Profiles[player]
	if not profile then
		return 1
	end
	return profile.Data.Level or 1
end

function DataManager.GetRankTier(player: Player): number
	local level = DataManager.GetLevel(player)
	return ExpConfig.getRankTier(level)
end

function DataManager.GetRankName(player: Player): string
	local profile = DataManager.Profiles[player]
	if not profile then
		return ExpConfig.RankNames[1]
	end
	return profile.Data.Rank or ExpConfig.RankNames[1]
end

function DataManager.GetLevelUpTime(player: Player): number
	local profile = DataManager.Profiles[player]
	if not profile then
		return 0
	end
	return profile.Data.LevelUpTime or 0
end

function DataManager.GetExpForNextLevel(player: Player): number
	local currentLevel = DataManager.GetLevel(player)
	return ExpConfig.getExpForLevel(currentLevel + 1)
end

function DataManager.GetExpProgress(player: Player): { current: number, required: number, percentage: number }
	local profile = DataManager.Profiles[player]
	if not profile then
		return { current = 0, required = 250, percentage = 0 }
	end

	local currentExp = profile.Data.Exp
	local currentLevel = profile.Data.Level
	local progress = ExpConfig.getProgress(currentExp, currentLevel)
	local nextLevel = math.min(currentLevel + 1, 101)

	return {
		current = currentExp,
		required = ExpConfig.getExpForLevel(nextLevel),
		percentage = math.floor(progress * 100)
	}
end

function DataManager.DebugPrintXpThresholds()
	for level = 1, 100 do
		local xpNeeded = ExpConfig.getXpPerLevelAt(level)
		print("Level", level, "| Cumulative:", ExpConfig.LevelThresholds[level], "| XP to next:", xpNeeded)
	end
	print("Total XP to 100:", ExpConfig.TotalExpToMax)
end

-- Player display (billboard above head)

function DataManager.AddRankDisplayToCharacter(player: Player, character: Model?)
	character = character or player.Character or player.CharacterAdded:Wait()
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local BillboardGui = Instance.new("BillboardGui", character)
	BillboardGui.Name = BILLBOARD_GUI_NAME
	BillboardGui.Adornee = humanoidRootPart
	BillboardGui.Size = UDim2.fromScale(3, 1)
	BillboardGui.SizeOffset = Vector2.new(0, 3.5)
	BillboardGui.AlwaysOnTop = true

	local uiListLayout = Instance.new("UIListLayout", BillboardGui)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.FillDirection = Enum.FillDirection.Vertical

	local playerRank = DataManager.GetRankName(player)
	local RankLabel = Instance.new("TextLabel", BillboardGui)
	RankLabel.Name = RANK_LABEL_NAME
	RankLabel.Text = playerRank
	RankLabel.TextColor3 = Color3.new(1, 1, 1)
	RankLabel.TextStrokeColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE
	RankLabel.TextStrokeTransparency = 0
	RankLabel.TextScaled = true
	RankLabel.BackgroundTransparency = 1
	RankLabel.LayoutOrder = 1
	RankLabel.FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold)
	RankLabel.Size = TEXT_LABEL_SIZE

	local playerLevel = DataManager.GetLevel(player)
	local NameLabel = Instance.new("TextLabel", BillboardGui)
	NameLabel.Name = NAME_LABEL_NAME
	NameLabel.Text = player.Name .. " (Lv. " .. playerLevel .. ")"
	NameLabel.TextColor3 = Color3.new(1, 1, 1)
	NameLabel.TextStrokeColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE
	NameLabel.TextStrokeTransparency = 0
	NameLabel.TextScaled = true
	NameLabel.BackgroundTransparency = 1
	NameLabel.LayoutOrder = 2
	NameLabel.FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold)
	NameLabel.Size = TEXT_LABEL_SIZE

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid
	humanoid.NameDisplayDistance = 0
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
end

function DataManager.UpdateLevelDisplay(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local PlayerBillboard = character:FindFirstChild(BILLBOARD_GUI_NAME)
	if not PlayerBillboard then return end

	local NameLabel = PlayerBillboard:FindFirstChild(NAME_LABEL_NAME) :: TextLabel
	if not NameLabel then return end

	local newLevel = DataManager.GetLevel(player)
	NameLabel.Text = player.Name .. " (Lv. " .. newLevel .. ")"
end

function DataManager.UpdateRankDisplay(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local PlayerBillboard = character:FindFirstChild(BILLBOARD_GUI_NAME)
	if not PlayerBillboard then return end

	local RankLabel = PlayerBillboard:FindFirstChild(RANK_LABEL_NAME) :: TextLabel
	if not RankLabel then return end

	local newRank = DataManager.GetRankName(player)
	RankLabel.Text = newRank
end

function DataManager.UpdatePlayerDisplay(player: Player)
	DataManager.UpdateRankDisplay(player)
	DataManager.UpdateLevelDisplay(player)
end

return DataManager