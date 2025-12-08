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
    trackerKey: string,  -- Links to ChallengeProgressTracker field
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
        trackerKey = "OutfitsSubmitted",
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
        trackerKey = "OutfitsVoted",
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
        trackerKey = "OutfitsVoted",
        targetAmount = 10,
        reward = {
            exp = 25,
            currency = 150
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