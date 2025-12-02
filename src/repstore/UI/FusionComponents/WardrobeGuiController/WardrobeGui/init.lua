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

local New = Fusion.New
local Children = Fusion.Children
local Value = Fusion.Value
local Out = Fusion.Out
local peek = Fusion.peek
local scope = Fusion:scoped()

type UsedAs<T> = Fusion.UsedAs<T>

return function(Toggled: Fusion.Value<boolean>)
	local wardrobeContainerVisible = Value(scope, true)
	local WardrobeContainer, AvatarContainer, CatalogContainer = WardrobeContainer(scope, Toggled) 

	local isToggled = scope:Computed(function(use, _) 
		return use(Toggled) == true
	end)
	

	return scope:New("ScreenGui")({
		Name = "WardrobeGui",
		Parent = localPlayerGui,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = isToggled,

		[Children] = { 
			WardrobeContainer
		}
	}),
		AvatarContainer,
		CatalogContainer
end