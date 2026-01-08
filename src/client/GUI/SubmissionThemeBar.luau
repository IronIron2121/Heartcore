--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local DataTables    = ReplicatedStorage:WaitForChild("DataTables")
local Utility       = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))
local ImageUris     = require(DataTables:WaitForChild("ImageUris"))

-- Instances
local centralPond               = workspace:WaitForChild("centralPond")
local pondModel                 = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = pondModel:WaitForChild("SubmissionBillboardHolder")
local BillboardGui              = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame                     = BillboardGui:WaitForChild("Frame")
local TimeLabel                 = Frame:WaitForChild("TimeLabel")
local ThemeLabel                = Frame:WaitForChild("ThemeLabel") 

-- Fusion 
local Fusion   = require(Utility:WaitForChild("Fusion"))
local scope    = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

local ThemeText = scope:Value("Loading...")
ThemeLabel:GetPropertyChangedSignal("Text"):Connect(function()
    ThemeText:set("Today's Fit Check theme: <font color=\"rgb(89, 247, 128)\">" .. ThemeLabel.Text .. "</font>")
end)
	
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

local function SubmissionThemeBar()
	local submissionThemeBar = scope:New "Frame" {
        Name = "Container",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0,0),
        BackgroundTransparency = 1,
        BackgroundColor3 = Color3.fromRGB(218, 35, 35),

        [Children] = {
            scope:New "UIListLayout"{
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            },

            scope:New "UIPadding" {
                PaddingTop = UDim.new(0.07, 0),
            },
            
            scope:New "TextLabel" {
                Name = "ThemeText",
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                RichText = true,
                Text = ThemeText,
                Size = UDim2.fromScale(1,0.2),
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

            scope:New "Frame" {
                Name = "TimerContainer",
                Size = UDim2.fromScale(1,0.2),
                BackgroundTransparency = 1,
                LayoutOrder = 1,

                [Children] = {
                    scope:New "UIListLayout"{
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                    },

                    scope:New "TextLabel" {
                        Name = "Time left text",
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                        Text = "Time left to submit:",
                        Size = UDim2.fromScale(0.3,1),
                        TextScaled = true,
                        LayoutOrder = 0,
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.fromRGB(255, 255, 255),

                        [Children] = {
                            scope:New "UIStroke" {
                                Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                Thickness = 2,
                            }
                        }
                    },

                    scope:New "ImageLabel" {
                        Name = "StopwatchIcon",
                        Size = UDim2.fromScale(0.5,1),
                        BackgroundTransparency = 1,
                        Image = ImageUris.StopwatchIcon,
                        LayoutOrder = 1,

                        [Children] = {
                            scope:New("UIAspectRatioConstraint") {
                                AspectRatio = 1
                            }
                        }
                    },
        
                    scope:New "TextLabel" {
                        Name = "Timer",
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
                        Text = TimeText,
                        Size = UDim2.fromScale(0.1,1),
                        TextScaled = true,
                        LayoutOrder = 2,
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.fromRGB(255, 255, 255),

                        [Children] = {
                            scope:New "UIStroke"{
                                Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                Thickness = 2,
                            }
                        }
                    }
                }
            }
        }
    } :: Frame

    return submissionThemeBar
end

return SubmissionThemeBar