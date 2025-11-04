--!strict

--

local PlayerVotedOutfitsTracker = {}

local playerList = {}

-- Adds the entry key / user ID of a viewed outfit to a player's no-no list
function PlayerVotedOutfitsTracker.AddOutfitToPlayerList(player: Player, outfitId: string)
    table.insert(playerList[player], outfitId)
end

function PlayerVotedOutfitsTracker.HasPlayerVotedOutfit(player: Player, outfitId: string)
    return table.find(playerList[player], outfitId) ~= nil
end

function PlayerVotedOutfitsTracker.OnPlayerAdded(player: Player)
    playerList[player] = {}
end

function PlayerVotedOutfitsTracker.OnPlayerRemoved(player: Player)
    playerList[player] = nil
end

return PlayerVotedOutfitsTracker