--!strict

--[[
	Gets the humanoid description from a given player
]]

local DEFAULT_DESC = Instance.new("HumanoidDescription")

function getHumanoidDescriptionFromPlayer(player: Player): HumanoidDescription?
	if not player then
		return DEFAULT_DESC
	end

	local character = player.Character or player.CharacterAdded:Wait()
	
	local humanoid  = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	
	local humanoidDescription = humanoid:FindFirstChildOfClass("HumanoidDescription")
	
	return humanoidDescription
end

return getHumanoidDescriptionFromPlayer
