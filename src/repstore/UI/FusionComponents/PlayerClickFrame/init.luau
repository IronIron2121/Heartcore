--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local StarterPlayer     = game:GetService("StarterPlayer")
local StarterGui        = game:GetService("StarterGui")

-- Folders
local Utility           = ReplicatedStorage:WaitForChild("Utility")
local UI                = ReplicatedStorage:WaitForChild("UI")
local FusionComponents  = UI:WaitForChild("FusionComponents")
local Widgets           = FusionComponents:WaitForChild("Widgets")
local Libraries         = ReplicatedStorage:WaitForChild("Libraries")
local GuiManagerLibrary = Libraries:WaitForChild("GuiManager")
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")

-- GUI
local ClientCustomisationService = require(StarterPlayer.StarterPlayerScripts.Clothing.ClientCustomisationService)
local Constants = require(ReplicatedStorage.Constants)
local getHumanoidDescriptionFromPlayer = require(ReplicatedStorage.Getters.getHumanoidDescriptionFromPlayer)
local getHumanoidDescriptionFromRig = require(ReplicatedStorage.Getters.getHumanoidDescriptionFromRig)
local Inspector = require(StarterPlayer.StarterPlayerScripts.Mannequins.Inspector)
local BaseButton = require(ReplicatedStorage.UI.FusionComponents.Widgets.BaseButtonTransparent)
local LoadingScreenManager = require(Libraries:WaitForChild("LoadingScreenManager"))
local ClientOutfitService = require(ReplicatedStorage.Utility.ClientOutfitService)
local PlayerInspectViewport = require(script.Parent.PlayerInspectViewport)
local CloseButton       = require(Widgets:WaitForChild("CloseButton"))

-- Modules
local callWithRetry         = require(Utility:WaitForChild("callWithRetry"))
local UI_CONSTANTS          = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion                = require(Utility:WaitForChild("Fusion"))
local GuiManager            = require(GuiManagerLibrary:WaitForChild("GuiManager"))

-- Instances
local localPlayer = Players.LocalPlayer

-- Fusion Modules
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>
type Value<T> = Fusion.Value<T>

-- Constants
local buttonSize = UDim2.fromScale(0.8, 0.1)

-- Remotes
local PlayerRequestedOutfitRF = Remotes:WaitForChild("PlayerRequestedOutfitRF")

-- Constants
local DEFAULT_NAME = " "

local NOT_FRIENDS_ADD_TEXT = "Add Friend"

local FRIENDS_ADD_TEXT = "Friend Added"

local _success, DEFAULT_THUMBNAIL = callWithRetry(function()
    return Players:GetUserThumbnailAsync(1640373, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)

local DEFAULT_DESC = Instance.new("HumanoidDescription")

local _success, DEFAULT_MODEL = callWithRetry(function()
    return Players:CreateHumanoidModelFromDescription(DEFAULT_DESC, Enum.HumanoidRigType.R15)
end)

local _success, DEFAULT_PLAYER = callWithRetry(function()  
    return Players:GetPlayerByUserId(Constants.DEFAULT_ID)
end)


--

local function PlayerClickFrame(scope: Fusion.Scope): (Frame, () -> ())
    -- Variables
    local inspectName = scope:Value(DEFAULT_NAME)
    local inspectThumbnail = scope:Value(DEFAULT_THUMBNAIL)
    local inspectModel = scope:Value(DEFAULT_MODEL)
    local inspectPlayer = scope:Value(DEFAULT_PLAYER)
    local inspectDescription = scope:Value(DEFAULT_DESC)

    local isFriend = scope:Value(false)

    local playerObs = scope:Observer(inspectPlayer)

    playerObs:onChange(function()  
        if not peek(inspectPlayer) then
            isFriend:set(false)
            return
        end

        local success, playerIsFriend = callWithRetry(function()  
            return localPlayer:IsFriendsWithAsync(peek(inspectPlayer).UserId) 
        end)    

        if not success then return end

        if playerIsFriend then
            isFriend:set(true)
            return
        else
            isFriend:set(false)
            return
        end
    end)

    local clickedPlayerContainer = scope:New "Frame" {
        Name = "ClickedPlayerContainer",
        Size = UDim2.fromScale(0.4, 1),
        BackgroundTransparency = 1,
        LayoutOrder = 2,

        [Children] = {
            PlayerInspectViewport(scope, {
                model = inspectModel,
                zIndex = 1
            }),
        }
    } :: Frame

    -- Functions
    local function onFrameOpened(props: {player: Player?, rig: Model?})
        LoadingScreenManager.show(clickedPlayerContainer)
        warn("Pushed frame")

        if props.player then
            local player = props.player
            task.spawn(function()
                inspectPlayer:set(player)

                -- Update the name tag
                inspectName:set(player.Name)

                -- Update the thumbnail
                local success, newThumbnail = callWithRetry(function()  
                    return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
                end)
                inspectThumbnail:set(success and newThumbnail or DEFAULT_THUMBNAIL)

                -- Update the description
                local descSuccess, humDesc = callWithRetry(function()
                    return getHumanoidDescriptionFromPlayer(player)
                end)

                if descSuccess then 
                    inspectDescription:set(humDesc) 
                end

                -- Get and set the new avatar
                local modelSuccess, newModel = callWithRetry(
                    function()  
                        return Players:CreateHumanoidModelFromDescriptionAsync(peek(inspectDescription), Enum.HumanoidRigType.R15)
                    end
                )
                if modelSuccess then
                    inspectModel:set(newModel)
                else
                    inspectModel:set(DEFAULT_MODEL)
                    warn("Failed to get humanoid model!", modelSuccess, newModel)
                end

                LoadingScreenManager.hide(clickedPlayerContainer)
            end)
        elseif props.rig then
            local rig = props.rig
            task.spawn(function()
                local outfitId = rig:GetAttribute("outfitId") :: string?

                if not outfitId then
                    LoadingScreenManager.hide(clickedPlayerContainer)
                    return
                end


                local success, outfit = callWithRetry(function()  
                    return PlayerRequestedOutfitRF:InvokeServer(outfitId)
                end)

                if not success or not outfit then 
                    LoadingScreenManager.hide(clickedPlayerContainer)
                    return 
                end
                 
                local player = Players:GetPlayerByUserId(outfit.userId)
                inspectPlayer:set(player)

                -- Update the name tag
                inspectName:set(player.Name)

                -- Update the thumbnail
                local success, newThumbnail = callWithRetry(function()  
                    return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size100x100)
                end)

                inspectThumbnail:set(success and newThumbnail or DEFAULT_THUMBNAIL)

                -- Update the description
                local descSuccess, humDesc = callWithRetry(function()
                    return getHumanoidDescriptionFromRig(rig)
                end)

                if descSuccess then 
                    inspectDescription:set(humDesc) 
                else
                    warn("Failed to get description from rig")
                end

                -- Get and set the new avatar
                local modelSuccess, newModel = callWithRetry(
                    function()  
                        return Players:CreateHumanoidModelFromDescriptionAsync(peek(inspectDescription), Enum.HumanoidRigType.R15)
                    end
                )
                if modelSuccess then
                    inspectModel:set(newModel)
                else
                    inspectModel:set(DEFAULT_MODEL)
                end

                LoadingScreenManager.hide(clickedPlayerContainer)
            end)
            
        end
    end 

    local function onFrameClosed()
        -- Reset player
        inspectPlayer:set(DEFAULT_PLAYER)
        -- Reset name tag
        inspectName:set(DEFAULT_NAME)
        -- Reset thumbnail
        inspectThumbnail:set(DEFAULT_THUMBNAIL) 
        -- Reset avatar viewport frame
        inspectModel:set(DEFAULT_MODEL)
        -- Reset humanoid description
        inspectDescription:set(DEFAULT_DESC)
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
                                BackgroundTransparency = 0,
                                
                                [Children] = {
                                    scope:New "UICorner" {
                                        CornerRadius = UDim.new(1, 0)
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

                            clickedPlayerContainer,

                            scope:New "ScrollingFrame" {
                                Name = "PlayerInspectOptionsPanel",
                                Size = UDim2.fromScale(0.3, 1),
                                Position = UDim2.fromScale(0, 0),
                                AnchorPoint = Vector2.new(0, 0),
                                CanvasSize = UDim2.fromScale(0, 0),
                                LayoutOrder = 2,
                                BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ScrollBarThickness = 6,
                                ScrollingDirection = Enum.ScrollingDirection.Y,
                                AutomaticCanvasSize = Enum.AutomaticSize.Y,

                                [Children] = {
                                    scope:New "UICorner" {
                                        CornerRadius = UDim.new(0.1, 0)
                                    },
                                    
                                    scope:New "UIListLayout" {
                                        SortOrder = Enum.SortOrder.LayoutOrder,
                                        FillDirection = Enum.FillDirection.Vertical,
                                        ItemLineAlignment = Enum.ItemLineAlignment.Center,
                                        VerticalAlignment = Enum.VerticalAlignment.Top,
                                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                                        Padding = UDim.new(0.05, 0)
                                    },

                                    scope:New "Frame" {
                                        Name = "StartBuffer",
                                        Size = UDim2.fromOffset(200, 10),
                                        BackgroundTransparency = 1,
                                        LayoutOrder = 1
                                    },

                                    BaseButton(scope, {
                                        text = "View Outfit",
                                        layoutOrder = 2,
                                        size = buttonSize,
                                        onActivated = function()
                                            Inspector.inspectDescription(peek(inspectDescription))
                                        end
                                    }),

                                    BaseButton(scope, {
                                        text = "Save Outfit",
                                        layoutOrder = 3,
                                        size = buttonSize,
                                        onActivated = function()
                                            GuiManager.PushNotificationCentre(
                                                "SaveOutfit", 
                                                "Are you sure you want to save this outfit?", 
                                                function()  
                                                    if not peek(inspectPlayer) then return end
                                                    ClientOutfitService.SaveInspectedPlayerOutfit(peek(inspectPlayer))
                                                    GuiManager.PopCentre()
                                                end
                                            )
                                        end
                                    }),

                                    BaseButton(scope, {
                                        text = "Wear Outfit",
                                        layoutOrder = 4,
                                        size = buttonSize,
                                        onActivated = function()
                                            ClientCustomisationService.PlayerEquippedInspectedPlayer(peek(inspectPlayer))
                                            GuiManager.PopCentre()
                                        end
                                    }),

                                    BaseButton(scope, {
                                        text = scope:Computed(function(use)  
                                            return use(isFriend) and FRIENDS_ADD_TEXT or NOT_FRIENDS_ADD_TEXT
                                        end),
                                        reactive = isFriend,
                                        active = isFriend,
                                        layoutOrder = 5,
                                        size = buttonSize,
                                        onActivated = function()
                                            if not peek(inspectPlayer) then return end 
                                            if peek(isFriend) then
                                                StarterGui:SetCore("PromptSendFriendRequest", peek(inspectPlayer))
                                            end
                                        end
                                    }),

                                    scope:New "Frame" {
                                        Name = "EndBuffer",
                                        Size = UDim2.fromOffset(200, 10),
                                        BackgroundTransparency = 1,
                                        LayoutOrder = 999
                                    },
                                }
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