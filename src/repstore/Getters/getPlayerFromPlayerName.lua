--!strict
local Players = game:GetService("Players")

function getPlayerFromPlayerName(playerName: string): Player?
	for _, player in pairs(Players:GetPlayers()) do
		if player.Name == playerName then
			return player
		end
	end
	return nil	
end

return getPlayerFromPlayerName