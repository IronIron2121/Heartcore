--!strict

-- Services
local ReplicatedStorage     = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local ImageUris             = require(ReplicatedStorage.DataTables.ImageUris)
local CONFIGURATION_NAMES   = require(ReplicatedStorage.Libraries.GuiManager.CONFIGURATION_NAMES)
local GuiManager            = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local CloseButton           = require(ReplicatedStorage.UI.FusionComponents.Widgets.CloseButton)
local Fusion                = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS          = require(Utility:WaitForChild("UI_CONSTANTS"))


-- Fusion Modules
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

--

local function FtuePop(scope: Fusion.Scope)
    local closeButton, toggled = CloseButton(scope, {
        onClick = function()
            GuiManager.PopCentre()
        end,
        position = UDim2.fromScale(0.98, 0.02),
        anchorPoint = Vector2.new(0.5,0.5),
        image = ImageUris.AuraClose,
        size = UDim2.fromScale(0.1,0.1)
    })

    local ftuePop = scope:New "Frame" {
        Name = "FtuePop",
        Size = UDim2.fromScale(0.5,0.9),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0,
        
        [Children] = {
            closeButton,
            scope: New "UICorner" {
                CornerRadius = UDim.new(0.1,0)
            },
            scope: New "UIGradient" {
                Color = ColorSequence.new(
                            Color3.fromHex("302a32"),
                            Color3.fromHex("a76c9f")
                        ),
                Rotation = 90
            },
            scope:New "UIStroke" {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Thickness = 3,
                Color = Color3.fromRGB(255, 211, 242)
            },
            scope:New "Frame"{
                Name = "TopBar",
                Size = UDim2.fromScale(1,0.3),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "ImageLabel" {
                        Name = "Logo",
                        AnchorPoint = Vector2.new(0.5,0.5),
                        Size = UDim2.fromScale(1,1.5),
                        Position = UDim2.fromScale(0.5,0.5),
                        Image = ImageUris.AuraLogo,
                        BackgroundTransparency = 1,

                        [Children] = {
                            scope:New "UIAspectRatioConstraint" {
                                AspectRatio = 1
                            }
                        }
                    }
                }
            },
            scope:New "Frame" {
                Name = "FTUETextFrame",
                Size = UDim2.fromScale(1,0.7),
                Position = UDim2.fromScale(0,0.3),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "TextLabel" {
                        Name = "Header",
                        Size = UDim2.fromScale(1,0.1),
                        BackgroundTransparency = 1,
                        Text = "You are entering the Heartcore dungeon...",
                        TextColor3 = Color3.fromHex("a76c9f"),
                        TextScaled = true,
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

                        [Children] = {
                            scope:New "UIStroke" {
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                                Thickness = 3,
                                Color = Color3.fromHex("f8cbff"),
                            },
                            scope:New "UIPadding" {
                                PaddingTop = UDim.new(0.1, 0),
                                PaddingBottom = UDim.new(0.1, 0),
                                PaddingLeft = UDim.new(0.1, 0),
                                PaddingRight = UDim.new(0.1, 0),
                            }
                        }
                    },
                    scope: New "Frame" {
                        Name = "BodyFrame",
                        AnchorPoint = Vector2.new(0.5,0.5),
                        Size = UDim2.fromScale(0.9,0.7),
                        Position = UDim2.fromScale(0.5,0.5),
                        BackgroundTransparency = 1,

                        [Children] = {
                            -- scope:New "UIListLayout" {
                            --     Padding = UDim.new(0.05, 0),
                            --     FillDirection = Enum.FillDirection.Vertical,
                            --     SortOrder = Enum.SortOrder.LayoutOrder,
                            --     HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            --     VerticalAlignment = Enum.VerticalAlignment.Center
                            -- },
                            -- scope:New "TextLabel" {
                            --     Name = "Body1",
                            --     Size = UDim2.fromScale(1,0.1),
                            --     BackgroundTransparency = 1,
                            --     LayoutOrder = 0,
                            --     RichText = true,
                            --     Text = "<font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'>Here you can:</stroke></font>",
                            --     TextScaled = true,
                            --     FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

                            --     [Children] = {
                            --         scope:New "UIPadding" {
                            --             PaddingTop = UDim.new(0, 0),
                            --             PaddingBottom = UDim.new(0, 0),
                            --             PaddingLeft = UDim.new(0.1, 0),
                            --             PaddingRight = UDim.new(0.1, 0),
                            --         }
                            --     }
                            -- },
                            scope:New "TextLabel" {
                                Name = "Body2",
                                Size = UDim2.fromScale(1,1),
                                BackgroundTransparency = 1,
                                LayoutOrder = 1,
                                RichText = true,
                                Text =  "<font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'>- </stroke></font><font color='#302a32'>Discover</font><font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'> official Au/Ra UGC</stroke></font>" ..
                                        "<br />" ..
                                        "<br />" ..
                                        "<font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'>- Play the</stroke></font><font color='#302a32'> Fit Check minigame</font><font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'> with Au/Ra on her livestream on</stroke></font><font color='#302a32'> DATE</font>" ..
                                        "<br />" ..
                                        "<br />" ..
                                        "<font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'>- Take part in the </stroke></font><font color='#302a32'>'Heartcore protagonist' dress-up challenge</font><font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'> and submit your creations to the </stroke></font><font color='#302a32'>Greenbeania discord</font>",
                                TextScaled = true,
                                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                                TextXAlignment = Enum.TextXAlignment.Left,

                                [Children] = {
                                    scope:New "UIPadding" {
                                        PaddingTop = UDim.new(0, 0),
                                        PaddingBottom = UDim.new(0, 0),
                                        PaddingLeft = UDim.new(0.05, 0),
                                        PaddingRight = UDim.new(0.05, 0),
                                    }
                                }
                            },
                            -- scope:New "TextLabel" {
                            --     Name = "Body3",
                            --     Size = UDim2.fromScale(1,0.1),
                            --     BackgroundTransparency = 1,
                            --     LayoutOrder = 2,
                            --     RichText = true,
                            --     Text = "<font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'>Have fun! And don't forget to </stroke></font><font color='#302a32'>report</font><font color='#a76c9f'><stroke color='#f8cbff' thickness='2' transparency='0' joins='round'> any bugs/issues/ideas to us!</stroke></font>",
                            --     TextScaled = true,
                            --     FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

                            --     [Children] = {
                            --         scope:New "UIPadding" {
                            --             PaddingTop = UDim.new(0, 0),
                            --             PaddingBottom = UDim.new(0, 0),
                            --             PaddingLeft = UDim.new(0.1, 0),
                            --             PaddingRight = UDim.new(0.1, 0),
                            --         }
                            --     }
                            -- },
                        }
                    }
                }
            }
        }

    } :: Frame

    return ftuePop
end

return FtuePop