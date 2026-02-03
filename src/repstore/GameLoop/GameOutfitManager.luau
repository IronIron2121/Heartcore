--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataManager = require(ServerScriptService.Data.DataManager)
local EXP_REWARDS = require(ServerScriptService.Data.EXP_REWARDS)

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SubmissionResultRE = Remotes:FindFirstChild("SubmissionResultRE") or Instance.new("RemoteEvent")
SubmissionResultRE.Name = "SubmissionResultRE"
SubmissionResultRE.Parent = Remotes

local CanSubmitRF = Remotes:FindFirstChild("CanSubmitRF") or Instance.new("RemoteFunction")
CanSubmitRF.Name = "CanSubmitRF"
CanSubmitRF.Parent = Remotes

--

local GameOutfitManager = {}

export type Outfit = {
	outfitId: string,
	userId: number,
	humanoidDescription: HumanoidDescription,
	votes: number,
	views: number,
}

-- Outfit storage: outfitId -> Outfit
local outfits: {[string]: Outfit} = {}

-- Track which players have submitted this round
local submittedPlayers: {[number]: boolean} = {}

-- Track which outfits each player has seen: userId -> {outfitId -> true}
local playerViews: {[number]: {[string]: boolean}} = {}

--

local function generateOutfitId(userId: number): string
	return tostring(userId) .. "_" .. tostring(DateTime.now().UnixTimestamp)
end

function GameOutfitManager.submitOutfit(player: Player, humanoidDescription: HumanoidDescription): boolean
	local userId = player.UserId
	
	if submittedPlayers[userId] then
		SubmissionResultRE:FireClient(player, {
			ok = false,
			msg = "You've already submitted an outfit this round!"
		})
		return false
	end
	
	local outfitId = generateOutfitId(userId)
	
	outfits[outfitId] = {
		outfitId = outfitId,
		userId = userId,
		humanoidDescription = humanoidDescription,
		votes = 0,
		views = 0,
	}

	submittedPlayers[userId] = true
	
	SubmissionResultRE:FireClient(player, {
		ok = true,
		msg = "Outfit submitted successfully!"
	})

	DataManager.AddExp(player, EXP_REWARDS.Actions.OUTFIT_SUBMIT)
	
	return true
end

function GameOutfitManager.getOutfits(): {[string]: Outfit}
	return outfits
end

function GameOutfitManager.getOutfit(outfitId: string): Outfit?
	return outfits[outfitId]
end

function GameOutfitManager.addVote(outfitId: string, voterUserId: number): boolean
	local outfit = outfits[outfitId]
	if not outfit then
		return false
	end
	
	if outfit.userId == voterUserId then
		return false
	end
	
	outfit.votes += 1
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

	warn("Unseen outfits: ")
	
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

function GameOutfitManager.getOutfitsByVotes(): {Outfit}
	local sorted = {}
	for _, outfit in pairs(outfits) do
		table.insert(sorted, outfit)
	end
	
	table.sort(sorted, function(a, b)
		return a.votes > b.votes
	end)
	
	return sorted
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

function GameOutfitManager.initialize()
	CanSubmitRF.OnServerInvoke = function(player: Player): boolean
		return GameOutfitManager.canSubmit(player.UserId)
	end
end

return GameOutfitManager