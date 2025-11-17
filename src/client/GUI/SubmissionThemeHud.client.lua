--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService") 


-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Instances
local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer.PlayerGui
local centralPond = workspace:WaitForChild("centralPond")
local pondModel = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = pondModel:WaitForChild("SubmissionBillboardHolder")
local BillboardGui = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame = BillboardGui:WaitForChild("Frame")
local TimeLabel = Frame:WaitForChild("TimeLabel")


-- Fusion Modules
local scope = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

	
local TimeText = scope:Value("Loading...")


local function updateTimeText(newText: string)
    TimeText:set(newText)
end

task.spawn(function()
        while true do
            task.wait(1)
            updateTimeText(TimeLabel.Text)
        end
    end)

local function initialiseGUI()
	local screenGUI = scope:New "ScreenGui" {
		Parent = PlayerGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Global
	}
    
	local frame = scope:New "Frame" {
        Name = "Container",
        Size = UDim2.fromScale(1, 0.1),
        Position = UDim2.fromScale(0,0),
        BackgroundTransparency = 1,
        BackgroundColor3 = Color3.fromRGB(218, 35, 35),
        Parent = screenGUI,

        [Children] = {
            scope:New "UIListLayout"{
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
            },
            scope:New "TextLabel" {
                Name = "ThemePlaceholder",
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                Text = "Theme Name",
                Size = UDim2.fromScale(0.5,0.5),
                TextScaled = true,
                LayoutOrder = 0,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),

                [Children] = {
                    scope:New "UIStroke"{
                        Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
                        Thickness = 2,
                    }
                }
            },
            scope:New "TextLabel" {
                Name = "Timer placeholder",
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                Text = TimeText,
                Size = UDim2.fromScale(0.5,0.5),
                TextScaled = true,
                LayoutOrder = 1,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),

                [Children] = {
                    scope:New "UIStroke"{
                    Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
                    Thickness = 2,
                    }
                }
            },
        }
    }
	
end

initialiseGUI()