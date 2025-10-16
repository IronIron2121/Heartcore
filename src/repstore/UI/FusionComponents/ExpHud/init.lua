--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")


-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Instances
local localPlayer = Players.LocalPlayer


local scope = Fusion:scoped()
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI
local PlayerGui = localPlayer.PlayerGui
local ExpBar = require(script:WaitForChild("ExpBar"))


local function initialiseGUI()
	local screenGUI = scope:New "ScreenGui" {
		Parent = PlayerGui
	}
	
	
	local _hudTopBar = scope:New "Frame" {
		Size = UDim2.fromScale(1,0.2),
		Position = UDim2.fromScale(0,0),
		AnchorPoint = Vector2.new(0,0),
		Parent = screenGUI,
		BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,

        [Children] = {
            scope:New "UIListLayout"{
                Padding = UDim.new(0.1,0),
                FillDirection = "Vertical",
                SortOrder = "LayoutOrder"
            },

            scope:New "Frame" {
                Name = "ExpBarContainer",
                Size = UDim2.fromScale(1,1),
                Position = UDim2.fromScale(0,0),
                LayoutOrder = 0,

                [Children] = {
                    ExpBar
                }
            }
        }
	}
	
end

initialiseGUI()