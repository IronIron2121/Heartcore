--!strict

-- Services
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Instances
local localPlayer = Players.LocalPlayer
local localPlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Gui Components
local WardrobeContainer = require(script:WaitForChild("WardrobeContainer"))
-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))

local Children = Fusion.Children
local Value = Fusion.Value
local scope = Fusion:scoped()

type UsedAs<T> = Fusion.UsedAs<T>

return function()
	local wardrobeContainerVisible = Value(scope, true)
	local WardrobeContainer, AvatarContainer, CatalogContainer = WardrobeContainer(scope) 
	
	return scope:New("ScreenGui")({
		Name = "WardrobeGui",
		Parent = localPlayerGui,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = true,

		[Children] = { 
			WardrobeContainer
		}
	}),
		AvatarContainer,
		CatalogContainer
end 