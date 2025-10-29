--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Instances
local localPlayer = Players.LocalPlayer


local scope = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI
local PlayerGui = localPlayer.PlayerGui
local ExpBar = require(FusionComponents:WaitForChild("ExpBar"))

 
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
        BackgroundTransparency = 1,
        --Visible = true,

        [Children] = {

            scope:New "Frame" {
                Name = "Container",
                Size = UDim2.fromScale(1,1),
                Position = UDim2.fromScale(0,0),
                BackgroundColor3 = Color3.new(0.654902, 0.215686, 0.215686),
                BackgroundTransparency = 1,

                [Children] = {
                    ExpBar(scope, {
                        name = "ExpBar"
                    })
                }
            },

            scope:New "Frame" {
                Name = "rankContainer",
                AnchorPoint = Vector2.new(0,0),
                Size = UDim2.fromScale(0.2, 0.2),
                Position = UDim2.fromScale(0.03,0.3),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "TextLabel" {
                        Name = "playerRankDisplay",
                        Size = UDim2.fromScale(1, 1),
                        Position = UDim2.fromScale(0,0),
                        BackgroundTransparency = 1,
                        Text = "Junior Fashionista",
                        TextColor3 = Color3.new(1,1,1),
                        TextStrokeColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                        TextStrokeTransparency = 0,
			            FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextScaled = true,
                        TextXAlignment = "Left",
                        TextYAlignment = "Top"
                    }
                }
            }

                
                
        }
    }
	
	
end

initialiseGUI()