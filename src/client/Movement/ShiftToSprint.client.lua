--!strict

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Instances
local localPlayer = Players.LocalPlayer
local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		Humanoid.WalkSpeed = 50	
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		Humanoid.WalkSpeed = 40
	end
end)