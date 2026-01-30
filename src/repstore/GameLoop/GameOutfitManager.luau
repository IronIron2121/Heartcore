--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

function GameOutfitManager.addView(outfitId: string): boolean
	local outfit = outfits[outfitId]
	if not outfit then
		return false
	end
	
	outfit.views += 1
	return true
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
end

function GameOutfitManager.initialize()
    warn("Init")
	CanSubmitRF.OnServerInvoke = function(player: Player): boolean
		return GameOutfitManager.canSubmit(player.UserId)
	end
end

return GameOutfitManager