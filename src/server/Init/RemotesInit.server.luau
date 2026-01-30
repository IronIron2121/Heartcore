--!strict
-- VotingRemotes.lua (Server)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")

local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))

-- Create remotes
local GetNextOutfitRF = Instance.new("RemoteFunction")
GetNextOutfitRF.Name = "GetNextOutfitRF"
GetNextOutfitRF.Parent = Remotes

local SubmitVoteRF = Instance.new("RemoteFunction")
SubmitVoteRF.Name = "SubmitVoteRF"
SubmitVoteRF.Parent = Remotes

local GetUnseenCountRF = Instance.new("RemoteFunction")
GetUnseenCountRF.Name = "GetUnseenCountRF"
GetUnseenCountRF.Parent = Remotes

local GetVotingThemeRF = Instance.new("RemoteFunction")
GetVotingThemeRF.Name = "GetVotingThemeRF"
GetVotingThemeRF.Parent = Remotes


-- Handlers
GetNextOutfitRF.OnServerInvoke = function(player: Player)
	local currentChampionId = nil -- Could pass this from client if needed for exclusion
	local outfit = GameOutfitManager.getUnseenOutfit(player, currentChampionId)
	
	if not outfit then
		return nil
	end
	
	-- Mark as seen and increment views
	GameOutfitManager.showOutfitToPlayer(player.UserId, outfit.outfitId)
	
	return {
		outfitId = outfit.outfitId,
		humanoidDescription = outfit.humanoidDescription,
	}
end

SubmitVoteRF.OnServerInvoke = function(player: Player, winnerOutfitId: string, loserOutfitId: string)
	if not winnerOutfitId or not loserOutfitId then
		return false
	end
	
	local success = GameOutfitManager.addVote(winnerOutfitId, player.UserId)
	return success
end

GetUnseenCountRF.OnServerInvoke = function(player: Player)
	return GameOutfitManager.getUnseenCount(player)
end

GetVotingThemeRF.OnServerInvoke = function(player: Player)
	return "ServerTest"
end