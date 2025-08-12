function GetHumanoidFromPlayer(player: Player)
	return player.Character:WaitForChild("Humanoid") :: Humanoid
end

return GetHumanoidFromPlayer
