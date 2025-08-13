--!strict

--[[
	setDescriptionSkinColor - A utility function to set all body parts on a HumanoidDescription to the same color
--]]

local function setDescriptionSkinColor(description: HumanoidDescription, color: Color3): HumanoidDescription
	description.HeadColor = color
	description.TorsoColor = color
	description.RightArmColor = color
	description.LeftArmColor = color
	description.RightLegColor = color
	description.LeftLegColor = color

	return description
end

return setDescriptionSkinColor