--!strict

local ReplicatedStorage 			= game:GetService("ReplicatedStorage")

local HumanoidDescriptionsFolder 	= ReplicatedStorage:WaitForChild("HumanoidDescriptions")

function getBaseHumanoidDescriptionFromPlayerName(playerName: string): HumanoidDescription ?
	for _, humanoidDescription in HumanoidDescriptionsFolder:GetChildren() do
		if humanoidDescription.Name == playerName then
			return humanoidDescription
		end
	end
	return nil
end

return getBaseHumanoidDescriptionFromPlayerName
