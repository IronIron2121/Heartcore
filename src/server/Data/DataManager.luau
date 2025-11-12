local DataManager = {}
DataManager.Profiles = {}

-- Level system configuration (levels 1-10, requiring 10, 20, 30... 100 XP)
local LEVEL_NAMES = {
    [1] = "Fashion Newbie",
    [2] = "Style Seeker", 
    [3] = "Trend Spotter",
    [4] = "Wardrobe Walker",
    [5] = "Outfit Observer",
    [6] = "Pattern Player",
    [7] = "Color Coordinator",
    [8] = "Fabric Finder",
    [9] = "Design Dabbler",
    [10] = "Style Master",
}

-- Helper function to get the start of a day (midnight UTC) for a given timestamp
local function getDayStart(timestamp: number): number
    return math.floor(timestamp / 86400) * 86400 -- 86400 seconds in a day
end

-- Helper function to get current day start
local function getCurrentDayStart(): number
    return getDayStart(DateTime.now().UnixTimestamp)
end

-- Helper function to get yesterday's day start
local function getYesterdayStart(): number
    return getCurrentDayStart() - 86400
end

-- Calculate what level a player should be based on their XP
local function calculateLevel(exp: number): number
    for level = 10, 1, -1 do -- Check from level 10 down to 1
        local requiredExp = level * 10
        if exp >= requiredExp then
            return level
        end
    end
    return 1 -- Default to level 1
end

-- Get the XP required for a specific level
local function getExpRequiredForLevel(level: number): number
    return level * 10
end

-- Get level name
function DataManager.GetLevelName(level: number): string
    return LEVEL_NAMES[level] or "Unknown Level"
end

function DataManager.AddExp(player: Player, amount: number)
    local profile = DataManager.Profiles[player]

    if not profile then
        return
    end

    local oldLevel = profile.Data.Level
    profile.Data.Exp += amount
    
    -- Check for level up
    local newLevel = calculateLevel(profile.Data.Exp)
    if newLevel > oldLevel then
        profile.Data.Level = newLevel
        profile.Data.LevelUpTime = DateTime.now().UnixTimestamp
        
        print(player.Name, "leveled up to level", newLevel, "(" .. DataManager.GetLevelName(newLevel) .. ")!")
        
        -- Update leaderstats
        if player:FindFirstChild("leaderstats") then
            if player.leaderstats:FindFirstChild("Level") then
                player.leaderstats.Level.Value = newLevel
            end
            if player.leaderstats:FindFirstChild("LevelName") then
                player.leaderstats.LevelName.Value = DataManager.GetLevelName(newLevel)
            end
        end
    else
        profile.Data.Level = newLevel
        profile.Data.LevelUpTime = DateTime.now().UnixTimestamp
        
        print(player.Name, "down-levelled to", newLevel, "(" .. DataManager.GetLevelName(newLevel) .. ")!")
        
        -- Update leaderstats
        if player:FindFirstChild("leaderstats") then
            if player.leaderstats:FindFirstChild("Level") then
                player.leaderstats.Level.Value = newLevel
            end
            if player.leaderstats:FindFirstChild("LevelName") then
                player.leaderstats.LevelName.Value = DataManager.GetLevelName(newLevel)
            end
        end
    end
    
    -- Update exp leaderstats
    if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Exp") then
        player.leaderstats.Exp.Value = profile.Data.Exp
    end
end

function DataManager.ResetPlayerLevel(player: Player)
    local profile = DataManager.Profiles[player]

    if not profile then
        return
    end

    profile.Data.Exp = 0
    
    DataManager.AddExp(player, 1)
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
    
    print("Processing login for:", player.Name)
    print("Current day start:", currentDayStart)
    print("Last login day start:", lastLoginDayStart) 
    print("Yesterday start:", yesterdayStart)
    
    -- Check if they've already logged in today
    if lastLoginDayStart == currentDayStart then
        print("Player already logged in today")
        return
    end
    
    -- Update login time
    profile.Data.LastLoginTime = currentTime
    
    -- Check if they logged in yesterday (consecutive day)
    if lastLoginDayStart == yesterdayStart then
        -- Consecutive login - maintain/increase streak
        profile.Data.LoginStreak += 1
        
        -- Calculate bonus: 1 base + 0.5 per streak day
        local expBonus = 1 + (profile.Data.LoginStreak * 0.5)
        DataManager.AddExp(player, expBonus)
        
        print("Consecutive login! Day", profile.Data.LoginStreak, "- Bonus:", expBonus, "exp")
        
    elseif lastLoginDayStart < yesterdayStart then
        -- Missed a day - reset streak but still give 1 exp for logging in
        profile.Data.LoginStreak = 1
        DataManager.AddExp(player, 1)
        
        print("Streak reset. New streak day 1 - Bonus: 1 exp")
        
    else
        -- First time login or same day login
        profile.Data.LoginStreak = 1
        DataManager.AddExp(player, 1)
        
        print("First login or same day - Streak: 1 - Bonus: 1 exp")
    end
    
    -- Update leaderstats to reflect changes
    if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Exp") then
        player.leaderstats.Exp.Value = profile.Data.Exp
    end
    
    print("Total exp:", profile.Data.Exp, "Login streak:", profile.Data.LoginStreak)
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

-- Debug function to manually test login streaks
function DataManager.DebugSetLastLogin(player: Player, daysAgo: number)
    local profile = DataManager.Profiles[player]
    if not profile then
        return
    end
    
    -- Set last login to X days ago at midnight
    local targetDay = getCurrentDayStart() - (daysAgo * 86400)
    profile.Data.LastLoginTime = targetDay
    print("Debug: Set", player.Name, "last login to", daysAgo, "days ago")
end

-- Get current level info
function DataManager.GetLevel(player: Player): number
    local profile = DataManager.Profiles[player]
    if not profile then
        return 1
    end
    return profile.Data.Level or 1
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
    if currentLevel >= 10 then
        return 0 -- Max level reached
    end
    return getExpRequiredForLevel(currentLevel + 1)
end

function DataManager.GetExpProgress(player: Player): {current: number, required: number, percentage: number}
    local profile = DataManager.Profiles[player]
    if not profile then
        return {current = 0, required = 10, percentage = 0}
    end
    
    local currentExp = profile.Data.Exp
    local currentLevel = profile.Data.Level
    local nextLevel = math.min(currentLevel + 1, 10)
    
    if currentLevel >= 10 then
        return {current = currentExp, required = 100, percentage = 100}
    end
    
    local requiredForNext = getExpRequiredForLevel(nextLevel)
    local requiredForCurrent = getExpRequiredForLevel(currentLevel)
    local progressExp = currentExp - requiredForCurrent
    local levelExpRange = requiredForNext - requiredForCurrent
    
    return {
        current = currentExp,
        required = requiredForNext,
        percentage = math.floor((progressExp / levelExpRange) * 100)
    }
end

return DataManager