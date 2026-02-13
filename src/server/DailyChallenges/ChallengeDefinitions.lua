--!strict

local ChallengeDefinitions = {}

-- Challenge types enum
export type ChallengeType = "SUBMIT_OUTFIT" | "VOTE_OUTFIT" | "LOGIN_STREAK" | "VIEW_OUTFITS" | "WIN_VOTES" | "META"

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
        description = "Submit 1 outfit in Fit Check",
        trackerKey = "OutfitsSubmitted",
        targetAmount = 1,
        reward = {
            exp = 60,
            currency = 50
        }
    },

    SUBMIT_2_OUTFITS = {
        id = "SUBMIT_2_OUTFITS",
        type = "SUBMIT_OUTFIT",
        name = "Daily Spammer",
        description = "Submit 2 outfits in Fit Check",
        trackerKey = "OutfitsSubmitted",
        targetAmount = 2,
        reward = {
            exp = 100,
            currency = 50
        }
    },

    PLACE_TOP_20 = {
        id = "PLACE_TOP_20",
        type = "WINNER_PLACEMENT",
        name = "Serious Stylist",
        description = "Come in the top 20 once",
        trackerKey = "PLACE_TOP_20",
        targetAmount = 1,
        reward = {
            exp = 80,
            currency = 50
        }
    },

    STYLE_5_PLUS = {
        id = "STYLE_5_PLUS",
        type = "OUTFIT_STYLE",
        name = "Serious Stylist",
        description = "Submit an outfit with more than 5 accessories in it",
        trackerKey = "StyleFivePlus",
        targetAmount = 1,
        reward = {
            exp = 60,
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
            exp = 50,
            currency = 150
        }
    },

    VOTE_20_OUTFITS = {
        id = "VOTE_20_OUTFITS",
        type = "VOTE_OUTFIT",
        name = "Style Hater",
        description = "Vote on 20 different outfits",
        trackerKey = "OutfitsVoted",
        targetAmount = 20,
        reward = {
            exp = 90,
            currency = 150
        }
    },

    -- Meta challenges
    COMPLETE_3_CHALLENGES = {
        id = "COMPLETE_3_CHALLENGES",
        type = "META",
        name = "Overachiever",
        description = "Complete 3 daily challenges",
        trackerKey = "ChallengesCompleted",
        targetAmount = 3,
        reward = {
            exp = 150,
            currency = 200
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