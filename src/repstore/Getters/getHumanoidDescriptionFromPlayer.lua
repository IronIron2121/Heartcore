--!strict

--[[
	Gets the humanoid description from a given player
]]

function getHumanoidDescriptionFromPlayer(player: Player): HumanoidDescription?
	local character = player.Character or player.CharacterAdded:Wait()
	
	local humanoid  = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	
	local humanoidDescription = humanoid:GetAppliedDescription()
	
	return humanoidDescription
end

return getHumanoidDescriptionFromPlayer
