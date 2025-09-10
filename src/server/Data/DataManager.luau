local DataManager = {}
DataManager.Profiles = {}

-- Helper function to get the start of a day (midnight UTC) for a given timestamp
local function getDayStart(timestamp: number): number
    return math.floor(timestamp / 86400) * 86400 -- 86400 seconds in a day
end

-- Helper function to get current day start
local function getCurrentDayStart(): number
    return getDayStart(os.time())
end

-- Helper function to get yesterday's day start
local function getYesterdayStart(): number
    return getCurrentDayStart() - 86400
end

function DataManager.AddExp(player: Player, amount: number)
    local profile = DataManager.Profiles[player]

    if not profile then
        return
    end

    profile.Data.Exp += amount
    player.leaderstats.Exp.Value = profile.Data.Exp -- Fixed from Gems to Exp
end

function DataManager.ProcessLogin(player: Player)
    local profile = DataManager.Profiles[player]
    
    if not profile then
        warn("No profile found for player:", player.Name)
        return
    end
    
    local currentTime = os.time()
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
    player.leaderstats.Exp.Value = profile.Data.Exp
    
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
    return os.time() - lastLogin
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

return DataManager