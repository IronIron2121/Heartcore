--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local Fusion = require(Utility:WaitForChild("Fusion"))
type UsedAs<T> = Fusion.UsedAs<T>
local Children = Fusion.Children

local function ChallengeCard(
    scope: Fusion.Scope,
    props: {
        layoutOrder: UsedAs<number>,
        description: UsedAs<string>?,
        progress: UsedAs<string>?,
        reward: UsedAs<string>?,
        isClaimed: UsedAs<boolean>?,
        onClaim: (() -> ())?
    }
): Frame
    local isHovered = scope:Value(false)
    
    local challengeFrame = scope:New "Frame" {
        Name = "ChallengeCard",
        Size = UDim2.fromScale(0.3, 0.8),
        LayoutOrder = props.layoutOrder,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0,

        [Children] = {
            scope:New "UICorner" {
                CornerRadius = UDim.new(0, 30)
            },

            -- Card content frame
            scope:New "Frame" {
                Name = "CardFrame",
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                ZIndex = 1,

                [Children] = {
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
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
                            },

                            scope:New "TextLabel" {
                                Name = "ChallengeDescription",
                                BackgroundTransparency = 1,
                                Size = UDim2.fromScale(1, 0.6),
                                Text = props.description or "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy",
                                TextWrapped = true,
                                TextSize = 26,
                                TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                FontFace = Font.new(UI_CONSTANTS.ROBOTO, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                            },

                            scope:New "TextLabel" {
                                Name = "ChallengeProgress",
                                BackgroundTransparency = 1,
                                Size = UDim2.fromScale(0.3, 0.2),
                                Text = props.progress or "4/5",
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
                                BackgroundTransparency = 1,
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
                                BackgroundTransparency = 1,
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
                                        Text = props.reward or "357",
                                        Size = UDim2.fromScale(0.3, 0.8),
                                        BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                        BackgroundTransparency = 0,
                                        TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
                                        TextSize = 26,
                                        FontFace = Font.new(UI_CONSTANTS.ROBOTO, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),

                                        [Children] = {
                                            scope:New "UICorner" {
                                                CornerRadius = UDim.new(0, 30)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },

            scope:New "Frame" {
                Name = "HoverOverlay",
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.5,
                Visible = scope:Computed(function(use)
                    return props.isClaimed or use(isHovered) 
                end),
                ZIndex = 10,

                [Children] = {
                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0, 30)
                    },

                    scope:New "TextButton" {
                        Name = "ClaimButton",
                        Size = UDim2.fromScale(0.6, 0.2),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        BackgroundColor3 = props.isClaimed and Color3.fromRGB(50,255,50) or Color3.fromRGB(255, 153, 0),
                        Text = props.isClaimed and "CLAIMED !" or "CLAIM !",
                        TextSize = 28,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),

                        [Fusion.OnEvent "Activated"] = function()
                            if props.onClaim then
                                props.onClaim()
                            end
                        end,

                        [Children] = {
                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0.5, 0)
                            },

                            scope:New "UIStroke" {
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Thickness = 3,
                                Color = props.isClaimed and Color3.fromRGB(0,100,10) and  Color3.fromRGB(200, 120, 0)
                            }
                        }
                    }
                }
            },
        }
    } :: Frame

    challengeFrame.MouseEnter:Connect(function()
        isHovered:set(true) 
        warn(props)
        warn(props.isClaimed)  
    end)

    challengeFrame.MouseLeave:Connect(function()
        isHovered:set(false)
    end)

    return challengeFrame
end

return ChallengeCard