--!strict
-- ExpConfig.lua

local ExpConfig = {}

-- XP curve tiers: { maxLevel, xpPerLevel }
ExpConfig.Tiers = {
	{ maxLevel = 10,  xpPerLevel = 250 },
	{ maxLevel = 20,  xpPerLevel = 400 },
	{ maxLevel = 40,  xpPerLevel = 550 },
	{ maxLevel = 70,  xpPerLevel = 700 },
	{ maxLevel = 90,  xpPerLevel = 900 },
	{ maxLevel = 100, xpPerLevel = 1200 },
}

-- Rank names by tier
ExpConfig.RankNames = {
	[1] = "Aura Farmer",
	[2] = "Wardrobe Walker",
	[3] = "Style Apprentice",
	[4] = "Trend Thrifter",
	[5] = "Style Icon",
	[6] = "Looksmaxxer",
	[7] = "Drip Master",
	[8] = "Runway Rizzer",
	[9] = "Fit Checker",
	[10] = "Fashion GOAT",
	[11] = "Ultimate Tastemaker",
}

-- XP rewards for actions
ExpConfig.Rewards = {
	OUTFIT_SUBMIT = 70,
    OUTFIT_QUALITY_BONUS = 20,
	VOTE_CAST = 6,
    VOTE_RECEIVED = 2,
	TOP_20 = 20
}

-- XP rewards for placements
ExpConfig.Placements = {
	[1] = 80,
	[2] = 50,
	[3] = 50,
}

-- Precomputed cumulative XP thresholds
ExpConfig.LevelThresholds = { [1] = 0 }

-- Build thresholds on module load
local function buildThresholds()
	local cumulativeXp = 0
	local tierIndex = 1
	
	for level = 1, 100 do
		ExpConfig.LevelThresholds[level] = cumulativeXp
		
		while tierIndex < #ExpConfig.Tiers and level >= ExpConfig.Tiers[tierIndex].maxLevel do
			tierIndex += 1
		end
		
		cumulativeXp += ExpConfig.Tiers[tierIndex].xpPerLevel
	end
	
	ExpConfig.LevelThresholds[101] = cumulativeXp
end

buildThresholds()

-- Helper functions

function ExpConfig.getLevelFromExp(exp: number): number
	for level = 100, 1, -1 do
		if exp >= ExpConfig.LevelThresholds[level] then
			return level
		end
	end
	return 1
end

function ExpConfig.getRankTier(level: number): number
	if level >= 100 then return 11 end
	if level >= 90 then return 10 end
	if level >= 80 then return 9 end
	if level >= 70 then return 8 end
	if level >= 60 then return 7 end
	if level >= 50 then return 6 end
	if level >= 40 then return 5 end
	if level >= 30 then return 4 end
	if level >= 20 then return 3 end
	if level >= 10 then return 2 end
	return 1
end

function ExpConfig.getRankName(level: number): string
	local tier = ExpConfig.getRankTier(level)
	return ExpConfig.RankNames[tier] or "Unknown"
end

function ExpConfig.getExpForLevel(level: number): number
	return ExpConfig.LevelThresholds[math.clamp(level, 1, 101)]
end

function ExpConfig.getXpPerLevelAt(level: number): number
	for _, tier in ipairs(ExpConfig.Tiers) do
		if level <= tier.maxLevel then
			return tier.xpPerLevel
		end
	end
	return ExpConfig.Tiers[#ExpConfig.Tiers].xpPerLevel
end

function ExpConfig.getProgress(currentExp: number, currentLevel: number): number
	local nextLevel = math.min(currentLevel + 1, 101)
	local xpForCurrent = ExpConfig.LevelThresholds[currentLevel]
	local xpForNext = ExpConfig.LevelThresholds[nextLevel]
	local xpIntoLevel = currentExp - xpForCurrent
	local xpNeeded = xpForNext - xpForCurrent
	
	if xpNeeded == 0 then
		return 1
	end
	
	return math.clamp(xpIntoLevel / xpNeeded, 0, 1)
end

-- Constants
ExpConfig.MaxLevel = 100
ExpConfig.TotalExpToMax = ExpConfig.LevelThresholds[101]

return ExpConfig