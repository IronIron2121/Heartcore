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

            scope:New "Frame" {
                Name = "ChallengesFrame",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0.01, 0)
                    },
                    scope:New "Frame" {
                        Name = "PlaceholderExample",
                        Size = UDim2.fromScale(0.3, 0.8),
                        LayoutOrder = 1,
                        [Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0, 30)
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