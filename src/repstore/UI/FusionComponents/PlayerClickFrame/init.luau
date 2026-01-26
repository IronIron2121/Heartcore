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
local PlayerInspectViewport = require(script.Parent.PlayerInspectViewport)
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

--[[

			Button(scope, {
				text = "Buy outfit",
				size = UDim2.fromScale(0.4, 0.05),
				position = UDim2.fromScale(1,1),
				anchorPoint = Vector2.new(1,1),
				zIndex = 3,
				visible = true,
				
				onActivated = function()
					ClientOutfitService.PurchasePlayerOutfit(localPlayer)
				end,
			}),
			
			Button(scope, {
				text = "Save Outfit",
				visible = true,
				size = UDim2.fromScale(0.4, 0.05),
				position = UDim2.fromScale(0,1),
				anchorPoint = Vector2.new(0,1),
				zIndex = 3,
				onActivated = function()
					GuiManager.PushNotificationCentre(
						"SaveOutfit", 
						"Are you sure you want to save this outfit?", 
						function()  

						end
					)
				end
			}),

]]

-- Constants
local DEFAULT_NAME = " "
local _success, DEFAULT_THUMBNAIL = callWithRetry(function()
    return Players:GetUserThumbnailAsync(1640373, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)

local DEFAULT_DESC = Instance.new("HumanoidDescription")

local _success, DEFAULT_MODEL = callWithRetry(function()
    return Players:CreateHumanoidModelFromDescription(DEFAULT_DESC, Enum.HumanoidRigType.R15)
end)

--

local function PlayerClickFrame(scope: Fusion.Scope): (Frame, () -> ())
    -- Variables
    local inspectName = scope:Value(DEFAULT_NAME)
    local inspectThumbnail = scope:Value(DEFAULT_THUMBNAIL)
    local inspectModel = scope:Value(DEFAULT_MODEL)

    -- Functions
    local function onFrameOpened(player: Player)
        -- Update the name tag
        inspectName:set(player.Name)
        -- Update the thumbnail
        local success, newThumbnail = callWithRetry(function()  
            return Players:GetUserThumbnailAsync(1640373, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
        end)
        inspectThumbnail:set(success and newThumbnail or DEFAULT_THUMBNAIL)
        -- Get and set the new avatar
        local modelSuccess, newModel = pcall(function()  
            return Players:CreateHumanoidModelFromUserIdAsync(player.UserId)
        end)

        inspectModel:set(modelSuccess and newModel or DEFAULT_MODEL)
    end 

    local function onFrameClosed()
        -- Reset name tag
        inspectName:set(DEFAULT_NAME)
        -- Reset thumbnail
        inspectThumbnail:set(DEFAULT_THUMBNAIL)
        -- Reset avatar viewport frame
        inspectModel:set(DEFAULT_MODEL)
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
                                Image = inspectThumbnail,
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
                                Text = inspectName,
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
                                Size = UDim2.fromScale(0.4, 1),
                                BackgroundTransparency = 1,
                                [Children] = {
                                    PlayerInspectViewport(scope, {
                                        model = inspectModel
                                    })
                                }
                            },

                            scope:New "Frame" {
                                Name = "OptionsContainer",
                                Size = UDim2.fromScale(0.4, 1),
                                BackgroundTransparency = 0
                            },


                        } 
                    },
                }
            },
        }
    } :: Frame

    return playerClickFrame, onFrameOpened
end

return PlayerClickFrame