--!strict

-- Services
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local Players               = game:GetService("Players")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Modules
local PlayerDisplayManager  = require(script.Parent.PlayerDisplayManager)
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
            GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.GameLoopConfig)
        end,
        position = UDim2.fromScale(1.03, 0),
        anchorPoint = Vector2.new(1,0)
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
                    scope:New "TextLabel" {
                        Name = "Body",
                        Size = UDim2.fromScale(1,0.9),
                        Position = UDim2.fromScale(0,0.1),
                        BackgroundTransparency = 1,
                        RichText = true,
                        Text = "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>Thank you so much for taking part! Below are some tips on how to play:</stroke></font>" ..
                                "<br /><br />" ..
                                "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>- </stroke></font><font color='#5B60D6'>Explore the island</font><font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'> and discover official music merch and trending UGC</stroke></font>" ..
                                "<br />" ..
                                "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>- </stroke></font><font color='#5B60D6'>Style and save</font><font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'> outfits to show your friends</stroke></font>" ..
                                "<br />" ..
                                "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>- Compete in the </stroke></font><font color='#5B60D6'>Fit Check minigame</font><font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'> and climb the </stroke></font><font color='#5B60D6'>Tastemaker ranks</font>" ..
                                "<br /><br />" ..
                                "<font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'>Have fun! And don't forget to </stroke></font><font color='#5B60D6'>report</font><font color='#FFFFFF'><stroke color='#5B60D6' thickness='2' transparency='0' joins='round'> any bugs/issues/ideas to us!</stroke></font>",
                        --TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
                        TextScaled = true,
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),

                        [Children] = {
                            -- scope:New "UIStroke" {
                            --     ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                            --     Thickness = 2,
                            --     Color = UI_CONSTANTS.TASTEMAKER_PURPLE
                            -- },
                            scope:New "UIPadding" {
                                PaddingTop = UDim.new(0.02, 0),
                                PaddingBottom = UDim.new(0.1, 0),
                                PaddingLeft = UDim.new(0.2, 0),
                                PaddingRight = UDim.new(0.2, 0),
                            }
                        }
                    }
                }
            }
        }

    } :: Frame

    return ftuePop
end

return FtuePop