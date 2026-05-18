--!strict
-- VotingRemotes.lua (Server)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GameLoop = ReplicatedStorage:WaitForChild("GameLoop")

local GameStateManager = require(ReplicatedStorage.GameLoop.GameStateManager)
local SerialisationService = require(ReplicatedStorage.Utility.SerialisationService)
local GameOutfitManager = require(GameLoop:WaitForChild("GameOutfitManager"))

-- Create remotes
local GetNextOutfitRF = Remotes:WaitForChild("GetNextOutfitRF") or Instance.new("RemoteFunction")
GetNextOutfitRF.Name = "GetNextOutfitRF"
GetNextOutfitRF.Parent = Remotes

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



GetVotingThemeRF.OnServerInvoke = function(player: Player)
	return GameStateManager.getCurrentTheme()
end