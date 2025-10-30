--!strict

--

local PlayerViewedOutfitsTracker = {}

local playerList = {}

-- Adds the entry key / user ID of a viewed outfit to a player's no-no list
function PlayerViewedOutfitsTracker.AddOutfitToPlayerList(player: Player, outfitId: number)
    table.insert(playerList[player], outfitId)
end

function PlayerViewedOutfitsTracker.HasPlayerViewedOutfit(player: Player, outfitId: number)
    return table.find(playerList[player], outfitId) ~= nil
end

function PlayerViewedOutfitsTracker.OnPlayerAdded(player: Player)
    playerList[player] = {}
end

function PlayerViewedOutfitsTracker.OnPlayerRemoved(player: Player)
    playerList[player] = nil
end

return PlayerViewedOutfitsTracker