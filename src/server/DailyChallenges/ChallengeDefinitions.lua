--!strict

local ChallengeDefinitions = {}

-- Challenge types enum
export type ChallengeType = "SUBMIT_OUTFIT" | "VOTE_OUTFIT" | "LOGIN_STREAK" | "VIEW_OUTFITS" | "WIN_VOTES"

-- Challenge definition structure
export type ChallengeDefinition = {
    id: string,
    type: ChallengeType,
    name: string,
    description: string,
    targetAmount: number,
    reward: {
        exp: number,
        currency: number?
    }
}

-- All possible challenges
ChallengeDefinitions.ALL_CHALLENGES = {
    -- Submission challenges
    SUBMIT_OUTFIT_DAILY = {
        id = "SUBMIT_OUTFIT_DAILY",
        type = "SUBMIT_OUTFIT",
        name = "Daily Fashionista",
        description = "Submit 1 outfit for today's theme",
        targetAmount = 1,
        reward = {
            exp = 10,
            currency = 50
        }
    },

    -- Voting challenges
    VOTE_5_OUTFITS = {
        id = "VOTE_5_OUTFITS",
        type = "VOTE_OUTFIT",
        name = "Tastemaker",
        description = "Vote on 5 different outfits",
        targetAmount = 5,
        reward = {
            exp = 15,
            currency = 75
        }
    },

    VOTE_10_OUTFITS = {
        id = "VOTE_10_OUTFITS",
        type = "VOTE_OUTFIT",
        name = "Style Critic",
        description = "Vote on 10 different outfits",
        targetAmount = 10,
        reward = {
            exp = 25,
            currency = 150
        }
    },

    -- Viewing challenges
    VIEW_20_OUTFITS = {
        id = "VIEW_20_OUTFITS",
        type = "VIEW_OUTFITS",
        name = "Window Shopper",
        description = "View 20 different outfits",
        targetAmount = 20,
        reward = {
            exp = 10,
            currency = 50
        }
    },

    -- Competition challenges
    GET_5_VOTES = {
        id = "GET_5_VOTES",
        type = "WIN_VOTES",
        name = "Rising Star",
        description = "Receive 5 votes on your outfit",
        targetAmount = 5,
        reward = {
            exp = 20,
            currency = 100
        }
    },

    GET_20_VOTES = {
        id = "GET_20_VOTES",
        type = "WIN_VOTES",
        name = "Fashion Icon",
        description = "Receive 20 votes on your outfit",
        targetAmount = 20,
        reward = {
            exp = 50,
            currency = 250
        }
    },

    -- Login streak (auto-awarded)
    LOGIN_STREAK_3 = {
        id = "LOGIN_STREAK_3",
        type = "LOGIN_STREAK",
        name = "Dedicated",
        description = "Log in for 3 days in a row",
        targetAmount = 3,
        reward = {
            exp = 30,
            currency = 150
        }
    },

    LOGIN_STREAK_7 = {
        id = "LOGIN_STREAK_7",
        type = "LOGIN_STREAK",
        name = "Fashion Devotee",
        description = "Log in for 7 days in a row",
        targetAmount = 7,
        reward = {
            exp = 100,
            currency = 500
        }
    },
}

-- Get all daily challenges
function ChallengeDefinitions.GetDailyChallengeSet(seed: number?): {ChallengeDefinition}
    local allChallenges = {}
    
    for _, challenge in pairs(ChallengeDefinitions.ALL_CHALLENGES) do
        table.insert(allChallenges, challenge)
    end
    
    return allChallenges
end

-- Get challenge definition by ID
function ChallengeDefinitions.GetChallenge(challengeId: string): ChallengeDefinition?
    return ChallengeDefinitions.ALL_CHALLENGES[challengeId]
end

return ChallengeDefinitions