--!strict

--[[
	Gets the humanoid description from a given player
]]

function getHumanoidDescriptionFromRig(rig: Model): HumanoidDescription?
	local humanoid  = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	
	return humanoid:FindFirstChildOfClass("HumanoidDescription")
end

return getHumanoidDescriptionFromRig