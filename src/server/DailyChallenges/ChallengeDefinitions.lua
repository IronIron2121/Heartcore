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

    --[[
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
    ]]


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