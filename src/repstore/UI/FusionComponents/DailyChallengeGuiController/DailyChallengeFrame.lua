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
                    
                    scope:New "Frame" {
                        Name = "PlaceholderExample",
                        Size = UDim2.fromScale(0.3, 0.8),
                        LayoutOrder = 1,
                        [Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0, 30)
                            },

                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Vertical,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                SortOrder = Enum.SortOrder.LayoutOrder
                            },

                            scope:New "Frame" {
                                Name = "DescriptionFrame",
                                LayoutOrder = 1,
                                Size = UDim2.fromScale(0.8, 0.65),
                                BackgroundTransparency = 1,

                                [Children] = {
                                    scope:New "UIListLayout" {
                                        FillDirection = Enum.FillDirection.Vertical,
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        SortOrder = Enum.SortOrder.LayoutOrder

                                    },

                                    scope:New "TextLabel" {
                                        Name = "ChallengeDescription",
                                        BackgroundTransparency = 1,
                                        Size = UDim2.fromScale(1, 0.6),
                                        Text = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy",
                                        TextWrapped = true,
                                        TextSize = 26,
                                        TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                        FontFace = Font.new(UI_CONSTANTS.ROBOTO, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                                    },

                                    scope:New "TextLabel" {
                                        Name = "ChallengeDescription",
                                        BackgroundTransparency = 1,
                                        Size = UDim2.fromScale(0.3, 0.2),
                                        Text = "4/5",
                                        TextWrapped = true,
                                        TextSize = 26,
                                        TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                        FontFace = Font.new(UI_CONSTANTS.ROBOTO, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                                        [Children] = {
                                            scope:New "UIStroke" {
                                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                                Thickness = 2,
                                                Color = UI_CONSTANTS.TASTEMAKER_PURPLE
                                            },

                                            scope:New "UICorner" {
                                                CornerRadius = UDim.new(0, 30)
                                            }
                                        }
                                    },


                                }
                            },

                            scope:New "Frame" {
                                Name = "Buffer",
                                LayoutOrder = 2,
                                Size = UDim2.fromScale(1, 0.05),
                                BackgroundTransparency = 1,
                                [Children] = {
                                    scope:New "TextLabel" {
                                        Size = UDim2.fromScale(1, 1),
                                        TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                        Text = "____________________"
                                    }
                                }
                            },

                            scope:New "Frame" {
                                Name = "RewardFrame",
                                LayoutOrder = 3,
                                Size = UDim2.fromScale(1, 0.30),
                                BackgroundTransparency = 1,
                                [Children] = {
                                    scope:New "UIListLayout" {
                                        FillDirection = Enum.FillDirection.Vertical,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Center,
                                        Padding = UDim.new(0.01, 0),
                                        SortOrder = Enum.SortOrder.LayoutOrder
                                    },

                                    scope:New "TextLabel" {
                                        Text = "Rewards:",
                                        TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                        Size = UDim2.fromScale(1, 0.5),
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        Position = UDim2.fromScale(0.5, 0.5),
                                        LayoutOrder = 1,
                                        FontFace = Font.new(UI_CONSTANTS.ROBOTO, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                                    },

                                    scope:New "Frame" {
                                        BackgroundTransparency = 1,
                                        Size = UDim2.fromScale(1, 0.5),
                                        AnchorPoint = Vector2.new(0.5, 0.5),
                                        Position = UDim2.fromScale(0.5, 0.5),
                                        LayoutOrder = 2,

                                        [Children] = {
                                            scope:New "UIListLayout" {
                                                FillDirection = Enum.FillDirection.Horizontal,
                                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                                Padding = UDim.new(0.01, 0),
                                                SortOrder = Enum.SortOrder.LayoutOrder
                                            },
                                            scope:New "TextLabel" {
                                                Text = "357",
                                                Size = UDim2.fromScale(0.3, 0.8),
                                                BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                                BackgroundTransparency = 0,
                                                TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
                                                TextSize = 26,
                                                FontFace = Font.new(UI_CONSTANTS.ROBOTO, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
                                                [Children] = scope:New "UICorner" {
                                                    CornerRadius = UDim.new(0, 30)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },

                    scope:New "Frame" {
                        Name = "PlaceholderExample",
                        Size = UDim2.fromScale(0.3, 0.8),
                        LayoutOrder = 2,

                        [Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0, 30)
                            }
                        }
                    },
                    
                    scope:New "Frame" {
                        Name = "PlaceholderExample",
                        Size = UDim2.fromScale(0.3, 0.8),
                        LayoutOrder = 3,
                        [Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0, 30)
                            }
                        }
                    },           
                    

                }
            }
        }
    } :: Frame

    return DailyChallengeFrame
end

return DailyChallengeFrame