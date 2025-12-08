--!strict

-- ChallengeServer.server.lua
-- Handles remote routing and challenge system initialization

warn("c server")
-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DailyChallenges = ServerScriptService:WaitForChild("DailyChallenges")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local ChallengeManager = require(DailyChallenges:WaitForChild("ChallengeManager"))

-- Remotes
local ResetPlayerChallenges = Remotes:WaitForChild("ResetPlayerChallenges")
local ClaimChallengeReward = Remotes:WaitForChild("ClaimChallengeReward")
local GetActiveChallenges = Remotes:WaitForChild("GetActiveChallenges")

--

local function onClaimChallengeReward(player: Player, challengeId: string): boolean
    if typeof(challengeId) ~= "string" then
        warn("Invalid challengeId type from", player.Name)
        return false
    end
    
    print(player.Name, "attempting to claim challenge:", challengeId)
    local success = ChallengeManager.ClaimReward(player, challengeId)
    
    if success then
        print(player.Name, "successfully claimed:", challengeId)
    else
        warn(player.Name, "failed to claim:", challengeId)
    end
    
    return success
end

local function onGetActiveChallenges(player: Player)
    local challenges = ChallengeManager.GetActiveChallenges(player)
    warn("Returning", #challenges, "challenges to", player.Name)

    return challenges
end

local function onResetPlayerChallenges(player: Player)
    ChallengeManager.ResetPlayerChallenges(player)
end

ClaimChallengeReward.OnServerInvoke = onClaimChallengeReward
GetActiveChallenges.OnServerInvoke = onGetActiveChallenges
ResetPlayerChallenges.OnServerEvent:Connect(onResetPlayerChallenges)