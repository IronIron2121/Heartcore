--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")


-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")
local ImageUris = require(DataTables:WaitForChild("ImageUris"))


-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- UI Components
local CloseButton = require(Widgets:WaitForChild("CloseButton"))
local ChallengeCard = require(Widgets:WaitForChild("ChallengeCard"))

--Instances
local centralPond = workspace:WaitForChild("centralPond")
local pondModel = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = pondModel:WaitForChild("SubmissionBillboardHolder")
local BillboardGui = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame = BillboardGui:WaitForChild("Frame")
local TimeLabel = Frame:WaitForChild("TimeLabel")

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
local scope = Fusion:scoped()

type UsedAs<T> = Fusion.UsedAs<T>
local Children = Fusion.Children
type Value<T> = Fusion.Value<T>

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

local function DailyChallengeFrame(
    scope: Fusion.Scope,
    props: {
        visible: Value<boolean>
    }
): Frame
    local DailyChallengeFrame = scope:New "Frame" {
        Name = "DailyChallengeFrame",
        BackgroundTransparency = UI_CONSTANTS.TRANSPARENCY_TRANSLUCENT,
        Size = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Visible = props.visible,

        [Children] = {
            CloseButton(scope, {
                size = UDim2.fromScale(0.1, 0.1),
                anchorPoint = Vector2.new(0.5, 0.5),
                position = UDim2.fromScale(1, 0),
                visibilityBoolean = props.visible
            }),

            scope:New "TextLabel" {
                Name = "ChallengesLabel",
                Size = UDim2.fromScale(0.3, 0.1),
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.fromScale(0.5, 0),
                BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                BackgroundTransparency = 0,
                Text = "DAILY MISSIONS",
                TextScaled = true,
                TextSize = 20,
                TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),

                [Children] = {
                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0, 10),
                    },

                    scope:New "UIStroke" {
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Thickness = 3,
                        Color = UI_CONSTANTS.COLOUR_WHITE
                    },

                    scope:New "UIPadding" {
                        PaddingTop = UDim.new(0.02,0),
                        PaddingBottom = UDim.new(0.02,0),
                        PaddingLeft = UDim.new(0.05,0),
                        PaddingRight = UDim.new(0.05,0),
                    }
                }
            },

            scope:New "UICorner" {
                CornerRadius = UDim.new(0, 30)
            },

            scope:New "Frame" {
                Name = "ChallengesFrame",
                Size = UDim2.fromScale(1,1),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "Frame" {
                        Name = "TimerContainer",
                        Size = UDim2.fromScale(1, 0.2),
                        BackgroundTransparency = 1,
              

                        [Children] = {
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                            },

                            scope:New "UIPadding" {
                                PaddingTop = UDim.new(0.2,0),
                                PaddingBottom = UDim.new(0.2,0),
                                PaddingLeft = UDim.new(0.2,0),
                                PaddingRight = UDim.new(0.2,0),
                            },

                            scope:New "Frame" {
                                Name = "Buffer",
                                Size = UDim2.fromScale(0.2,1),
                                BackgroundTransparency = 1,
                                LayoutOrder = 0,
                            },

                            scope:New "ImageLabel"{
                                Image = ImageUris.StopwatchIcon,
                                Size = UDim2.fromScale(0.6, 0.6),
                                LayoutOrder = 1,
                                BackgroundTransparency = 1,
                                                    
                                [Children] = {
                                    scope:New "UIAspectRatioConstraint" {
                                        AspectRatio = 1,
                                        DominantAxis = Enum.DominantAxis.Width,
                                    }
                                }
                            },

                            scope:New "TextLabel" {
                                Name = "Timer",
                                Text = TimeText,
                                TextScaled = true,
                                Size = UDim2.fromScale(0.3, 0.7),
                                LayoutOrder = 2,
                                BackgroundTransparency = 1,
                                TextColor3 = Color3.fromRGB(92, 96, 214)
                            },

                            scope:New "Frame" {
                                Name = "Buffer",
                                Size = UDim2.fromScale(0.2,1),
                                BackgroundTransparency = 1,
                                LayoutOrder = 3,
                            },
                        }
                    },            
                    
                    scope:New "Frame" {
                        Name = "ChallengeCardsFrame",
                        Size = UDim2.fromScale(1, 0.9),
                        BackgroundTransparency = 1,
                        Position = UDim2.fromScale(0, 0.1),

                        [Children] = {
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Horizontal,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0.01, 0),
                                SortOrder = Enum.SortOrder.LayoutOrder
                            },
                            
                            ChallengeCard(scope, {
                                layoutOrder = 1,
                                description = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy",
                                progress = "4/5",
                                reward = "357",
                                onClaim = function()
                                    print("Claimed challenge 1!")
                                end
                            }),

                            ChallengeCard(scope, {
                                layoutOrder = 2,
                                description = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy",
                                progress = "4/5",
                                reward = "357",
                                onClaim = function()
                                    print("Claimed challenge 2!")
                                end
                            }),

                            ChallengeCard(scope, {
                                layoutOrder = 3,
                                description = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy",
                                progress = "4/5",
                                reward = "357",
                                onClaim = function()
                                    print("Claimed challenge 3!")
                                end
                            }),
                        }
                    }
                }
            }
        }
    } :: Frame

    return DailyChallengeFrame
end

return DailyChallengeFrame