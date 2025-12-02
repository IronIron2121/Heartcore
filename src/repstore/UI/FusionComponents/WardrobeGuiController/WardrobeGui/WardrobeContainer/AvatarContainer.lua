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

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))

return function(scope: Fusion.Scope)
	return scope:New "Frame" {
		Name = "AvatarContainer",
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0,0,0,0), -- this will be over-ridden by UIListLayout
		Size = UDim2.fromScale(0.3, 1),

		[Fusion.Children] = {
			scope:New "UIListLayout" {
				Padding = UDim.new(0, 10),
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			}
		}
	}
end