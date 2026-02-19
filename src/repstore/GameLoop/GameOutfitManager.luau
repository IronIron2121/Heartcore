--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Folders
local DailyChallenges = ServerScriptService:WaitForChild("DailyChallenges")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Data = ServerScriptService:WaitForChild("Data")

-- Modules
local GetNumAccessoriesInHumanoidDescription = require(Utility.GetNumAccessoriesInHumanoidDescription)
local ServerCustomisationService = require(Utility.ServerCustomisationService)
local ChallengeManager = require(DailyChallenges.ChallengeManager)
local ExpConfig = require(Libraries.ExpConfig)
local DataManager = require(Data.DataManager)

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SubmissionResultRE = Remotes:FindFirstChild("SubmissionResultRE") or Instance.new("RemoteEvent")
SubmissionResultRE.Name = "SubmissionResultRE" 
SubmissionResultRE.Parent = Remotes

--

local GameOutfitManager = {}

export type Outfit = {
	outfitId: string,
	userId: number,
	humanoidDescription: HumanoidDescription,
	votes: number,
	views: number,
	score: number,
}

-- Outfit storage: outfitId -> Outfit
local outfits: {[string]: Outfit} = {}

-- Track which players have submitted this round
local submittedPlayers: {[number]: boolean} = {}

-- Track which outfits each player has seen: userId -> {outfitId -> true}
local playerViews: {[number]: {[string]: boolean}} = {}

-- Podium outfits persist across reset() so winner rigs remain inspectable
local podiumOutfits: {[string]: Outfit} = {}

--

local function generateOutfitId(userId: number): string
	return tostring(userId) .. "_" .. tostring(DateTime.now().UnixTimestamp)
end

function GameOutfitManager.submitOutfit(player: Player, humanoidDescription: HumanoidDescription): boolean
	local userId = player.UserId
	
	-- Remove previous submission if resubmitting
	if submittedPlayers[userId] then
		for id, outfit in outfits do
			if outfit.userId == userId then
				outfits[id] = nil
				break
			end
		end
	end

	local outfitId = generateOutfitId(userId)

	outfits[outfitId] = {
		outfitId = outfitId,
		userId = userId,
		humanoidDescription = humanoidDescription,
		votes = 0,
		views = 0,
		score = 0,
	} 

	submittedPlayers[userId] = true
	
	SubmissionResultRE:FireClient(player, {
		ok = true,
		msg = "Outfit submitted successfully!"
	})
	
	local numAccessories = GetNumAccessoriesInHumanoidDescription(humanoidDescription)
	ChallengeManager.OnOutfitSubmitted(player, numAccessories)
	DataManager.AddExp(player, ExpConfig.Rewards.OUTFIT_SUBMIT)
	if ServerCustomisationService.getNumberOfItemsEquipped(player) > 3 then
		DataManager.AddExp(player, ExpConfig.Rewards.OUTFIT_QUALITY_BONUS)
	end
	
	return true
end

function GameOutfitManager.getOutfits(): {[string]: Outfit}
	return outfits
end

function GameOutfitManager.getOutfit(outfitId: string): Outfit?
	return outfits[outfitId] or podiumOutfits[outfitId]
end

function GameOutfitManager.setPodiumOutfits(outfitList: {Outfit})
	podiumOutfits = {}
	for _, outfit in ipairs(outfitList) do
		podiumOutfits[outfit.outfitId] = outfit
	end
end

function GameOutfitManager.addVote(player: Player, outfitId: string): boolean
	local outfit = outfits[outfitId]
	local voterUserId = player.UserId
	if not outfit then
		return false
	end
	
	if outfit.userId == voterUserId then
		return false
	end

	outfit.votes += 1
	
	-- Calculate score: wins / views (safe since views must be > 0 to vote)
	if outfit.views > 0 then
		outfit.score = outfit.votes / outfit.views
	end

	-- Award XP asynchronously
	task.spawn(function()
		DataManager.AddExp(player, ExpConfig.Rewards.VOTE_RECEIVED)
		ChallengeManager.OnOutfitVoted(player)
	end)

	return true
end

function GameOutfitManager.showOutfitToPlayer(userId: number, outfitId: string): boolean
	local outfit = outfits[outfitId]
	if not outfit then
		return false
	end
	
	if not playerViews[userId] then
		playerViews[userId] = {}
	end
	
	-- Only increment view if they haven't seen it before
	if not playerViews[userId][outfitId] then
		playerViews[userId][outfitId] = true
		outfit.views += 1
		
		-- Recalculate score when views change
		if outfit.views > 0 then
			outfit.score = outfit.votes / outfit.views
		end
	end
	
	return true
end

function GameOutfitManager.hasSeen(userId: number, outfitId: string): boolean
	if not playerViews[userId] then
		return false
	end
	
	return playerViews[userId][outfitId] == true
end

function GameOutfitManager.getUnseenOutfit(player: Player, excludeOutfitId: string?): Outfit?
	local userId = player.UserId
	local seen = playerViews[userId] or {}
	
	local unseen: {Outfit} = {}
	for outfitId, outfit in pairs(outfits) do
		local isOwnOutfit = outfit.userId == userId
		local isExcluded = excludeOutfitId and outfitId == excludeOutfitId
		local alreadySeen = seen[outfitId]
		
		if not isOwnOutfit and not isExcluded and not alreadySeen then
			table.insert(unseen, outfit)
		end
	end
	
	if #unseen == 0 then
		return nil
	end
	
	table.sort(unseen, function(a, b)
		return a.views < b.views
	end)

	return unseen[1]
end

function GameOutfitManager.getUnseenCount(player: Player): number
	local userId = player.UserId
	local seen = playerViews[userId] or {}
	
	local count = 0
	for outfitId, outfit in pairs(outfits) do
		if outfit.userId ~= userId and not seen[outfitId] then
			count += 1
		end
	end
	
	return count
end

function GameOutfitManager.getOutfitsByScore(): {Outfit}
	local sorted = {}
	for _, outfit in pairs(outfits) do
		table.insert(sorted, outfit)
	end
	
	table.sort(sorted, function(a, b)
		-- Primary: score (descending)
		-- Tiebreaker: votes (descending)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return a.votes > b.votes
	end)
	
	return sorted
end

-- Keep for backwards compatibility if needed
function GameOutfitManager.getOutfitsByVotes(): {Outfit}
	return GameOutfitManager.getOutfitsByScore()
end

function GameOutfitManager.hasSubmitted(userId: number): boolean
	return submittedPlayers[userId] == true
end

function GameOutfitManager.canSubmit(userId: number): boolean
	return not submittedPlayers[userId]
end

function GameOutfitManager.getSubmissionCount(): number
	local count = 0
	for _ in pairs(outfits) do
		count += 1
	end
	return count
end

function GameOutfitManager.reset()
	outfits = {}
	submittedPlayers = {}
	playerViews = {}
end

return GameOutfitManager