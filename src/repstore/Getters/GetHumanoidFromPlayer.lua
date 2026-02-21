function GetHumanoidFromPlayer(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character:WaitForChild("Humanoid") :: Humanoid
end

return GetHumanoidFromPlayer
