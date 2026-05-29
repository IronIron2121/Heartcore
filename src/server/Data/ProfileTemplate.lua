local ProfileTemplate = {
    Exp = 0,
    Level = 1,         -- Current level (starts at 1)
    LastLoginTime = 0, -- Unix timestamp of last login
    LoginStreak = 0,   -- Number of consecutive days logged in
    LevelUpTime = 0,   -- Unix timestamp of last level up
    LastOutfitSubmittedTime = 0, 

    DailyChallenges = {
        -- Structure:
        -- ["CHALLENGE_ID"] = {
        --     id = "CHALLENGE_ID",
        --     progress = 0,
        --     claimed = false
        -- }
    } :: {[string]: {id: string, progress: number, claimed: boolean}},

    ChallengeProgressTracker = {
        OutfitsSubmitted = 0,
        OutfitsVoted = 0,
        OutfitsViewed = 0,
        VotesReceived = 0
    },
    
    LastChallengeResetTime = 0,
    SeenMessages = {} :: {[string]: boolean},

}

return ProfileTemplate