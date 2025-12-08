--!strict

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")

-- Instances
local localPlayer = Players.LocalPlayer
local localPlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Gui Components
local OpenDailyChallengeGuiButton = require(FusionComponents:WaitForChild("OpenDailyChallengeGuiButton"))
local DailyChallengeFrame =  require(script.Parent:WaitForChild("DailyChallengeFrame"))

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local scope = Fusion:scoped()
type UsedAs<T> = Fusion.UsedAs<T>

return function()
	local OpenDailyChallengeGuiButton, Toggled = OpenDailyChallengeGuiButton(scope)  
	local ChallengeFrame = DailyChallengeFrame(scope, {
		visible = Toggled
	})

	local DailyChallengeGui = scope:New "ScreenGui" {
		Name = "DailyChallengeGui",
		Parent = localPlayerGui,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		[Fusion.Children] = {
			OpenDailyChallengeGuiButton,
			ChallengeFrame
		}
	}

	return DailyChallengeGui, Toggled
end 