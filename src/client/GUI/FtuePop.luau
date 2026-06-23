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
        anchorPoint = Vector2.new(0.5,0.5)
    })

    local ftuePop = scope:New "Frame" {
        Name = "FtuePop",
        Size = UDim2.fromScale(0.5,0.9),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0.3,
        
        [Children] = {
            closeButton,
            scope: New "UICorner" {
                CornerRadius = UDim.new(0.1,0)
            },
            scope:New "UIStroke" {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Thickness = 3,
                Color = UI_CONSTANTS.TASTEMAKER_PURPLE
            },
            scope:New "Frame"{
                Name = "TopBar",
                Size = UDim2.fromScale(1,0.2),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "ImageLabel" {
                        Name = "Logo",
                        AnchorPoint = Vector2.new(0.5,0.5),
                        Size = UDim2.fromScale(1,1.5),
                        Position = UDim2.fromScale(0.5,0.5),
                        Image = ImageUris.TastemakerLogo,
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
                Size = UDim2.fromScale(1,0.8),
                Position = UDim2.fromScale(0,0.2),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "TextLabel" {
                        Name = "Header",
                        Size = UDim2.fromScale(1,0.1),
                        BackgroundTransparency = 1,
                        Text = "Welcome to the Tastemaker Alpha Test!",
                        TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
                        TextScaled = true,
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

                        [Children] = {
                            scope:New "UIStroke" {
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                                Thickness = 3,
                                Color = UI_CONSTANTS.TASTEMAKER_PURPLE
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
                        AnchorPoint = Vector2.new(0,0.5),
                        Size = UDim2.fromScale(1,0.8),
                        Position = UDim2.fromScale(0,0.5),
                        BackgroundTransparency = 1,

                        [Children] = {
                            scope:New "UIListLayout" {
                                Padding = UDim.new(0.05, 0),
                                FillDirection = Enum.FillDirection.Vertical,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center
                            },
                            scope:New "TextLabel" {
                                Name = "Body1",
                                Size = UDim2.fromScale(1,0.1),
                                BackgroundTransparency = 1,
                                LayoutOrder = 0,
                                RichText = true,
                                Text = "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>Thank you so much for taking part! Below are some tips on how to play:</stroke></font>",
                                TextScaled = true,
                                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

                                [Children] = {
                                    scope:New "UIPadding" {
                                        PaddingTop = UDim.new(0, 0),
                                        PaddingBottom = UDim.new(0, 0),
                                        PaddingLeft = UDim.new(0.1, 0),
                                        PaddingRight = UDim.new(0.1, 0),
                                    }
                                }
                            },
                            scope:New "TextLabel" {
                                Name = "Body2",
                                Size = UDim2.fromScale(1,0.5),
                                BackgroundTransparency = 1,
                                LayoutOrder = 1,
                                RichText = true,
                                Text =  "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>- </stroke></font><font color='#5B60D6'>Explore the island</font><font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'> and discover official music merch and trending UGC</stroke></font>" ..
                                        "<br />" ..
                                        "<br />" ..
                                        "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>- </stroke></font><font color='#5B60D6'>Style and save</font><font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'> outfits to show your friends</stroke></font>" ..
                                        "<br />" ..
                                        "<br />" ..
                                        "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>- Compete in the </stroke></font><font color='#5B60D6'>Fit Check minigame</font><font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'> and climb the </stroke></font><font color='#5B60D6'>Tastemaker ranks</font>",
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
                            scope:New "TextLabel" {
                                Name = "Body3",
                                Size = UDim2.fromScale(1,0.1),
                                BackgroundTransparency = 1,
                                LayoutOrder = 2,
                                RichText = true,
                                Text = "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>Have fun! And don't forget to </stroke></font><font color='#5B60D6'>report</font><font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'> any bugs/issues/ideas to us!</stroke></font>",
                                TextScaled = true,
                                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

                                [Children] = {
                                    scope:New "UIPadding" {
                                        PaddingTop = UDim.new(0, 0),
                                        PaddingBottom = UDim.new(0, 0),
                                        PaddingLeft = UDim.new(0.1, 0),
                                        PaddingRight = UDim.new(0.1, 0),
                                    }
                                }
                            },
                        }
                    }
                }
            }
        }

    } :: Frame

    return ftuePop
end

return FtuePop