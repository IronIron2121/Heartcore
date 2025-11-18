--!strict



-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")


-- Instances
local localPlayer = Players.LocalPlayer
local localPlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Gui Components
local OpenWardrobeButton = require(FusionComponents:WaitForChild("OpenWardrobeButton"))


-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local scope = Fusion:scoped()

return function()
	local OpenWardrobeButton, Toggled = OpenWardrobeButton(scope) 


	local MainHudGui = scope:New "ScreenGui" {
		Name = "MainHudGui",
		Parent = localPlayerGui,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		[Fusion.Children] = {
			OpenWardrobeButton,			
		}
	}

	return MainHudGui, Toggled
end