--!strict

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Data = ServerScriptService:WaitForChild("Data")

-- Modules
local ChallengeDefinitions = require(script.Parent:WaitForChild("ChallengeDefinitions"))
local DataManager = require(Data:WaitForChild("DataManager"))

-- Remotes
local UpdateChallengeProgress = Remotes:WaitForChild("UpdateChallengeProgress")

--

local ChallengeManager = {}

-- Helper to check if it's a new day for the player
local function isNewDay(lastResetTime: number): boolean
    local currentDayStart = math.floor(DateTime.now().UnixTimestamp / 86400) * 86400
    local lastResetDayStart = math.floor(lastResetTime / 86400) * 86400
    return currentDayStart > lastResetDayStart
end

-- Initialize challenges for a player (called on join or daily reset)
function ChallengeManager.InitialiseChallenges(player: Player)
    warn("Initialising challenges!")
    local profile = DataManager.Profiles[player]
    if not profile then
        warn("No profile found for player:", player.Name)
        return
    end

    -- Initialize tracker if it doesn't exist
    if not profile.Data.ChallengeProgressTracker then
        profile.Data.ChallengeProgressTracker = {
            OutfitsSubmitted = 0,
            OutfitsVoted = 0,
            OutfitsViewed = 0,
            VotesReceived = 0
        }
    end

    -- Check if we need to reset daily challenges
    local lastResetTime = profile.Data.LastChallengeResetTime or 0
    
    if isNewDay(lastResetTime) then
        ChallengeManager.ResetPlayerChallenges(player)
    end
end

-- Reset player's challenges (resets tracker and claim status)
function ChallengeManager.ResetPlayerChallenges(player: Player)
    print("Resetting challenges for", player.Name)
    local profile = DataManager.Profiles[player]
    if not profile then
        warn("No profile found for player:", player.Name)
        return
    end
    
    -- Reset progress tracker
    profile.Data.ChallengeProgressTracker = {
        OutfitsSubmitted = 0,
        OutfitsVoted = 0,
        OutfitsViewed = 0,
        VotesReceived = 0
    }
    
    -- Get all challenges and reset claim status
    local dailyChallenges = ChallengeDefinitions.GetDailyChallengeSet()
    
    profile.Data.DailyChallenges = {}
    for _, challenge in ipairs(dailyChallenges) do
        profile.Data.DailyChallenges[challenge.id] = {
            id = challenge.id,
            claimed = false
        }
    end
    
    profile.Data.LastChallengeResetTime = DateTime.now().UnixTimestamp
    print("Reset", #dailyChallenges, "challenges for", player.Name)
    
    -- Notify client of all progress updates
    for _, challenge in ipairs(dailyChallenges) do
        ChallengeManager.SendChallengeUpdate(player, challenge.id, false)
    end
end

-- Get current progress for a challenge
function ChallengeManager.getChallengeProgress(player: Player, challengeId: string): number
    local profile = DataManager.Profiles[player]
    if not profile then return 0 end
    
    local definition = ChallengeDefinitions.GetChallenge(challengeId)
    if not definition then return 0 end
    
    local trackerValue = profile.Data.ChallengeProgressTracker[definition.trackerKey] or 0
    return math.min(trackerValue, definition.targetAmount)
end

-- Increment a tracker stat
function ChallengeManager.IncrementTrackerStat(player: Player, trackerKey: string, amount: number?)
    local profile = DataManager.Profiles[player]
    if not profile then return end
    
    amount = amount or 1
    
    if not profile.Data.ChallengeProgressTracker then
        profile.Data.ChallengeProgressTracker = {}
    end
    
    local oldValue = profile.Data.ChallengeProgressTracker[trackerKey] or 0
    profile.Data.ChallengeProgressTracker[trackerKey] = oldValue + amount
    
    print(string.format(
        "%s: %s = %d",
        player.Name,
        trackerKey,
        profile.Data.ChallengeProgressTracker[trackerKey]
    ))
    
    -- Notify client of all challenges that use this tracker
    for challengeId, _ in pairs(profile.Data.DailyChallenges or {}) do
        local definition = ChallengeDefinitions.GetChallenge(challengeId)
        if definition and definition.trackerKey == trackerKey then
            local challengeData = profile.Data.DailyChallenges[challengeId]
            ChallengeManager.SendChallengeUpdate(player, challengeId, challengeData.claimed)
        end
    end
end

-- Claim challenge reward
function ChallengeManager.ClaimReward(player: Player, challengeId: string): boolean
    local profile = DataManager.Profiles[player]
    if not profile then return false end
    
    local challengeData = profile.Data.DailyChallenges and profile.Data.DailyChallenges[challengeId]
    if not challengeData then
        warn("Challenge not found:", challengeId)
        return false
    end
    
    -- Check if already claimed
    if challengeData.claimed then
        warn("Challenge already claimed:", challengeId)
        return false
    end
    
    -- Check if challenge is completed
    local definition = ChallengeDefinitions.GetChallenge(challengeId)
    if not definition then
        warn("Challenge definition not found:", challengeId)
        return false
    end
    
    local progress = ChallengeManager.getChallengeProgress(player, challengeId)
    if progress < definition.targetAmount then
        warn("Challenge not completed:", challengeId, progress, "/", definition.targetAmount)
        return false
    end
    
    -- Award rewards
    challengeData.claimed = true
    
    -- Award EXP
    if definition.reward.exp then
        DataManager.AddExp(player, definition.reward.exp)
    end
    
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
    for challengeId, challengeData in pairs(profile.Data.DailyChallenges or {}) do
        local definition = ChallengeDefinitions.GetChallenge(challengeId)
        if definition then
            local progress = ChallengeManager.getChallengeProgress(player, challengeId)
            
            table.insert(challenges, {
                id = challengeId,
                progress = progress,
                target = definition.targetAmount,
                claimed = challengeData.claimed,
                definition = definition
            })
        end
    end
    
    return challenges
end

-- Send challenge update to client
function ChallengeManager.SendChallengeUpdate(player: Player, challengeId: string, claimed: boolean)
    local progress = ChallengeManager.getChallengeProgress(player, challengeId)
    warn("Updating", player, "on challenge", challengeId, progress)

    UpdateChallengeProgress:FireClient(player, {
        id = challengeId,
        progress = progress,
        claimed = claimed
    })
end

-- Convenience functions for incrementing tracker stats
function ChallengeManager.OnOutfitSubmitted(player: Player)
    ChallengeManager.IncrementTrackerStat(player, "OutfitsSubmitted", 1)
end

function ChallengeManager.OnOutfitVoted(player: Player)
    ChallengeManager.IncrementTrackerStat(player, "OutfitsVoted", 1)
end

function ChallengeManager.OnOutfitViewed(player: Player, amount: number?)
    ChallengeManager.IncrementTrackerStat(player, "OutfitsViewed", amount or 1)
end

function ChallengeManager.OnVotesReceived(player: Player, amount: number)
    ChallengeManager.IncrementTrackerStat(player, "VotesReceived", amount)
end

return ChallengeManager