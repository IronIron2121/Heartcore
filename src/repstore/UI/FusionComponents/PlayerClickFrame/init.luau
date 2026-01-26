--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- Folders
local DataTables        = ReplicatedStorage:WaitForChild("DataTables")
local Utility           = ReplicatedStorage:WaitForChild("Utility")
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local UI                = ReplicatedStorage:WaitForChild("UI")
local FusionComponents  = UI:WaitForChild("FusionComponents")
local Widgets           = FusionComponents:WaitForChild("Widgets")
local Libraries         = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerLibrary = Libraries:WaitForChild("GuiManager")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local CloseButton       = require(Widgets:WaitForChild("CloseButton"))

-- Modules
local SerialisationService  = require(Utility:WaitForChild("SerialisationService"))
local callWithRetry         = require(Utility:WaitForChild("callWithRetry"))
local ImageUris             = require(DataTables:WaitForChild("ImageUris"))
local UI_CONSTANTS          = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion                = require(Utility:WaitForChild("Fusion"))
local GuiManager            = require(GuiManagerLibrary:WaitForChild("GuiManager"))

-- Fusion Modules
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
type Value<T> = Fusion.Value<T>

-- Types
type TileData = {
    userId: number,
    humanoidDescription: HumanoidDescription?,
    playerName: string,
    votes: number,
    views: number
}

--

local function PlayerClickFrame(scope: Fusion.Scope): (Frame, () -> ())
    -- Variables
    local function onFrameOpened(force: boolean?)
        -- Get the new avatar
        -- Update the name tag
        -- Update the thumbnail
    end

    local function onFrameClosed()
        -- Reset avatar viewport frame
        -- Reset name tag
        -- Reset thumbnail
    end

    local playerClickFrame = scope:New "Frame" {
        Name = "PlayerClickFrame",
        Size = UDim2.fromScale(0.8, 0.8),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 1,
        Visible = true,

        [Children] = {
            CloseButton(scope, {
                size = UDim2.fromScale(0.1, 0.1),
                anchorPoint = Vector2.new(0.5, 0.5),
                position = UDim2.fromScale(1, 0),

                onClick = function()
                    GuiManager.PopCentre()
                    onFrameClosed()
                end
            }),

            scope:New "Frame" {
                Name = "Background",
                Size = UDim2.fromScale(1,1),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundColor3 = Color3.new(1,1,1),
                BackgroundTransparency = 0.2,

                [Children] = {    
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder
                    },

                    scope:New "UICorner" {
                        CornerRadius = UDim.new(0.05)
                    },
                }
            },

            scope:New "Frame" {
                Name = "Body",
                LayoutOrder = 2,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                [Children] = { 
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Vertical,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    },

                    scope:New "Frame" {
                        Name = "TopBar",
                        Size = UDim2.fromScale(1, 0.1),
                        LayoutOrder = 1,
                        BackgroundTransparency = 1,

                        [Children] = {
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                Padding = UDim.new(0.02,0),
                            },

                            scope:New "ImageLabel"{
                                Name = "PlayerThumbnail",
                                Image = ImageUris.StopwatchIcon,
                                Size = UDim2.fromScale(1, 1),
                                LayoutOrder = 1,
                                BackgroundTransparency = 1,
                                
                                [Children] = {
                                    scope:New "UICorner" {
                                        CornerRadius = UDim.new(0.1, 0)
                                    },

                                    scope:New "UIAspectRatioConstraint" {
                                        AspectRatio = 1,
                                        DominantAxis = Enum.DominantAxis.Width,
                                    }
                                }
                            },

                            scope:New "TextLabel" {
                                Name = "PlayerNameLabel",
                                Text = "PLAYER_NAME_GOES_HERE",
                                TextScaled = true,
                                Size = UDim2.fromScale(0.3, 1),
                                LayoutOrder = 2,
                                BackgroundTransparency = 1,
                                TextColor3 = Color3.fromRGB(92, 96, 214),
                                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
                            }
                        }
                    },

                    scope:New "Frame" {
                        Name = "Buffer",
                        Size = UDim2.fromScale(1, 0.03),
                        LayoutOrder = 0,
                        BackgroundTransparency = 1
                    },

                    scope:New "Frame" {
                        Name = "PlayerContainer",
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 0.8),
                        LayoutOrder = 2,

                        [Children] = {
                            scope:New "UIListLayout" {
                                FillDirection = Enum.FillDirection.Horizontal,
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                VerticalAlignment = Enum.VerticalAlignment.Center,
                                Padding = UDim.new(0.01, 0),
                                Wraps = false
                            },

                            scope:New "UICorner" {
                                CornerRadius = UDim.new(0.05)
                            },

                            scope:New "Frame" {
                                Name = "ClickedPlayerContainer",
                                Size = UDim2.fromScale(0.5, 1),
                                BackgroundTransparency = 1
                            },

                            scope:New "Frame" {
                                Name = "OptionsContainer",
                                Size = UDim2.fromScale(0.5, 1),
                                BackgroundTransparency = 0
                            }
                        } 
                    },
                }
            },
        }
    } :: Frame

    return playerClickFrame, onFrameOpened
end

return PlayerClickFrame