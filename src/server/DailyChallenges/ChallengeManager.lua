--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Data = ServerScriptService:WaitForChild("Data")
local DataManager = require(Data:WaitForChild("DataManager"))
local ChallengeDefinitions = require(script.Parent:WaitForChild("ChallengeDefinitions"))

local ChallengeManager = {}

-- Helper to check if it's a new day for the player
local function isNewDay(lastResetTime: number): boolean
    local currentDayStart = math.floor(DateTime.now().UnixTimestamp / 86400) * 86400
    local lastResetDayStart = math.floor(lastResetTime / 86400) * 86400
    return currentDayStart > lastResetDayStart
end

-- Initialize challenges for a player (called on join or daily reset)
function ChallengeManager.InitializeChallenges(player: Player)
    local profile = DataManager.Profiles[player]
    if not profile then
        warn("No profile found for player:", player.Name)
        return
    end

    -- Check if we need to reset daily challenges
    local lastResetTime = profile.Data.LastChallengeResetTime or 0
    
    if isNewDay(lastResetTime) then
        print("Resetting challenges for", player.Name)
        
        -- Get all challenges
        local dailyChallenges = ChallengeDefinitions.GetDailyChallengeSet()
        
        -- Reset challenge progress
        profile.Data.DailyChallenges = {}
        for _, challenge in ipairs(dailyChallenges) do
            profile.Data.DailyChallenges[challenge.id] = {
                id = challenge.id,
                progress = 0,
                claimed = false
            }
        end
        
        profile.Data.LastChallengeResetTime = DateTime.now().UnixTimestamp
    end
end

-- Update challenge progress
function ChallengeManager.UpdateProgress(player: Player, challengeType: string, amount: number?)
    local profile = DataManager.Profiles[player]
    if not profile then return end
    
    amount = amount or 1
    
    -- Find all challenges of this type that aren't completed
    for challengeId, challengeProgress in pairs(profile.Data.DailyChallenges or {}) do
        local definition = ChallengeDefinitions.GetChallenge(challengeId)
        
        if definition and definition.type == challengeType then
            -- Update progress
            if challengeProgress.progress < definition.targetAmount then
                challengeProgress.progress = math.min(
                    challengeProgress.progress + amount,
                    definition.targetAmount
                )
                
                print(string.format(
                    "%s progress: %s (%d/%d)",
                    player.Name,
                    challengeId,
                    challengeProgress.progress,
                    definition.targetAmount
                ))
                
                -- Notify client of progress update
                ChallengeManager.SendChallengeUpdate(player, challengeId, challengeProgress)
            end
        end
    end
end

-- Claim challenge reward
function ChallengeManager.ClaimReward(player: Player, challengeId: string): boolean
    local profile = DataManager.Profiles[player]
    if not profile then return false end
    
    local challengeProgress = profile.Data.DailyChallenges and profile.Data.DailyChallenges[challengeId]
    if not challengeProgress then
        warn("Challenge not found:", challengeId)
        return false
    end
    
    -- Check if already claimed
    if challengeProgress.claimed then
        warn("Challenge already claimed:", challengeId)
        return false
    end
    
    -- Check if challenge is completed
    local definition = ChallengeDefinitions.GetChallenge(challengeId)
    if not definition then
        warn("Challenge definition not found:", challengeId)
        return false
    end
    
    if challengeProgress.progress < definition.targetAmount then
        warn("Challenge not completed:", challengeId, challengeProgress.progress, "/", definition.targetAmount)
        return false
    end
    
    -- Award rewards
    challengeProgress.claimed = true
    
    -- Award EXP
    if definition.reward.exp then
        DataManager.AddExp(player, definition.reward.exp)
    end
    
    -- Award currency (if you have a currency system)
    if definition.reward.currency then
        -- DataManager.AddCurrency(player, definition.reward.currency)
        -- TODO: Implement currency system
    end
    
    print(string.format(
        "%s claimed %s: +%d exp",
        player.Name,
        challengeId,
        definition.reward.exp or 0
    ))
    
    return true
end

-- Get all active challenges for a player
function ChallengeManager.GetActiveChallenges(player: Player): {{id: string, progress: number, target: number, claimed: boolean, definition: any}}
    local profile = DataManager.Profiles[player]
    if not profile then return {} end
    
    local challenges = {}
    for challengeId, challengeProgress in pairs(profile.Data.DailyChallenges or {}) do
        local definition = ChallengeDefinitions.GetChallenge(challengeId)
        if definition then
            table.insert(challenges, {
                id = challengeId,
                progress = challengeProgress.progress,
                target = definition.targetAmount,
                claimed = challengeProgress.claimed,
                definition = definition
            })
        end
    end
    
    return challenges
end

-- Send challenge update to client
function ChallengeManager.SendChallengeUpdate(player: Player, challengeId: string, challengeProgress: any)
    local UpdateChallengeProgress = ReplicatedStorage:FindFirstChild("UpdateChallengeProgress")
    if UpdateChallengeProgress then
        UpdateChallengeProgress:FireClient(player, {
            id = challengeId,
            progress = challengeProgress.progress,
            claimed = challengeProgress.claimed
        })
    end
end

-- Convenience functions for common challenge types
function ChallengeManager.OnOutfitSubmitted(player: Player)
    ChallengeManager.UpdateProgress(player, "SUBMIT_OUTFIT", 1)
end

function ChallengeManager.OnOutfitVoted(player: Player)
    ChallengeManager.UpdateProgress(player, "VOTE_OUTFIT", 1)
end

function ChallengeManager.OnOutfitViewed(player: Player, amount: number?)
    ChallengeManager.UpdateProgress(player, "VIEW_OUTFITS", amount or 1)
end

function ChallengeManager.OnVotesReceived(player: Player, amount: number)
    ChallengeManager.UpdateProgress(player, "WIN_VOTES", amount)
end

function ChallengeManager.OnLoginStreakUpdated(player: Player, streakCount: number)
    -- Check if player reached any streak milestones
    local profile = DataManager.Profiles[player]
    if not profile then return end
    
    for challengeId, challengeProgress in pairs(profile.Data.DailyChallenges or {}) do
        local definition = ChallengeDefinitions.GetChallenge(challengeId)
        if definition and definition.type == "LOGIN_STREAK" then
            if streakCount >= definition.targetAmount and not challengeProgress.claimed then
                challengeProgress.progress = definition.targetAmount
                ChallengeManager.SendChallengeUpdate(player, challengeId, challengeProgress)
            end
        end
    end
end

return ChallengeManager