--!strict
-- VotingRemotes.lua (Server)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")

local DataManager = require(ServerScriptService.Data.DataManager)
local GameStateManager = require(ReplicatedStorage.GameLoop.GameStateManager)
local ExpConfig = require(ReplicatedStorage.Libraries.ExpConfig)
local SerialisationService = require(ReplicatedStorage.Utility.SerialisationService)
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))

-- Create remotes
local GetNextOutfitRF = Remotes:WaitForChild("GetNextOutfitRF") or Instance.new("RemoteFunction")
GetNextOutfitRF.Name = "GetNextOutfitRF"
GetNextOutfitRF.Parent = Remotes

local SubmitVoteRF = Remotes:WaitForChild("SubmitVoteRF") or Instance.new("RemoteFunction")
SubmitVoteRF.Name = "SubmitVoteRF"
SubmitVoteRF.Parent = Remotes

local GetUnseenCountRF = Remotes:WaitForChild("GetUnseenCountRF") or Instance.new("RemoteFunction")
GetUnseenCountRF.Name = "GetUnseenCountRF"
GetUnseenCountRF.Parent = Remotes

local GetVotingThemeRF = Remotes:WaitForChild("GetVotingThemeRF") or Instance.new("RemoteFunction")
GetVotingThemeRF.Name = "GetVotingThemeRF"
GetVotingThemeRF.Parent = Remotes
 

-- Handlers
GetNextOutfitRF.OnServerInvoke = function(player: Player)
	local currentChampionId = nil -- Could pass this from client if needed for exclusion
	local outfit = GameOutfitManager.getUnseenOutfit(player, currentChampionId)
	
	if not outfit then
		warn("No more outfits at getnextoutfit")
		GameStateManager.markFinishedVoting(player)
		print(player.Name, "finished voting!")
		return nil
	end
	
	-- Mark as seen and increment views
	GameOutfitManager.showOutfitToPlayers(player.UserId, outfit.outfitId)
	
	return {
		outfitId = outfit.outfitId,
		humanoidDescription = SerialisationService.SerialiseHumanoidDescription(outfit.humanoidDescription),
	}
end

SubmitVoteRF.OnServerInvoke = function(player: Player, winnerOutfitId: string, loserOutfitId: string)
	if not winnerOutfitId or not loserOutfitId then
		return false
	end
	
	local success = GameOutfitManager.addVote(player, winnerOutfitId)
	DataManager.AddExp(player, ExpConfig.Rewards.VOTE_CAST)
	return success
end

GetUnseenCountRF.OnServerInvoke = function(player: Player)
	local count = GameOutfitManager.getUnseenCount(player)
	if count == 0 then
		warn("No more outfits at getunseencount")
		GameStateManager.markFinishedVoting(player)
	end
	return count
end

GetVotingThemeRF.OnServerInvoke = function(player: Player)
	return GameStateManager.getCurrentTheme()
end