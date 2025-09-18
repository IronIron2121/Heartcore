local ProfileTemplate = {
    Exp = 0,
    LastLoginTime = 0, -- Unix timestamp of last login
    LoginStreak = 0,   -- Number of consecutive days logged in
    Level = 1,         -- Current level (starts at 1)
    LevelUpTime = 0,   -- Unix timestamp of last level up
}

return ProfileTemplate