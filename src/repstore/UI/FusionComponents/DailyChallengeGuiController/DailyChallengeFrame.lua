--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Widgets = FusionComponents:WaitForChild("Widgets")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- UI Components
local CloseButton = require(Widgets:WaitForChild("CloseButton"))
local ChallengeCard = require(Widgets:WaitForChild("ChallengeCard"))

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
type UsedAs<T> = Fusion.UsedAs<T>
local Children = Fusion.Children
type Value<T> = Fusion.Value<T>

--

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
                Size = UDim2.fromScale(0.25, 0.1),
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.fromScale(0.5, 0),
                BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                BackgroundTransparency = 0,
                Text = "DAILY CHALLENGES",
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
                }
            },

            scope:New "UICorner" {
                CornerRadius = UDim.new(0, 30)
            },

            scope:New "Frame" {
                Name = "ChallengesFrame",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

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
    } :: Frame

    return DailyChallengeFrame
end

return DailyChallengeFrame