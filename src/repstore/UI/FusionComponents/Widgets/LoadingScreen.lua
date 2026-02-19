--!strict
-- LoadingScreen.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Child = require(ReplicatedStorage.Utility.Fusion.Instances.Child)
local Children = require(ReplicatedStorage.Utility.Fusion.Instances.Children)
local ChallengeCard = require(script.Parent.ChallengeCard)
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local Children = Fusion.Children
local peek = Fusion.peek

type UsedAs<T> = Fusion.UsedAs<T>

function Frame(
    scope: Fusion.Scope,
    props: {
        name: UsedAs<string>?,
        active: UsedAs<boolean>?,
        visible: UsedAs<boolean>?,
        size: UsedAs<UDim2>?,
        position: UsedAs<UDim2>?,
        layoutOrder: UsedAs<number>?,
        anchorPoint: UsedAs<Vector2>?,
        cornered: boolean?,
        text: UsedAs<string>?,
        textScaled: UsedAs<boolean>?,
        backgroundColor: UsedAs<Color3>?,
        backgroundTransparency: UsedAs<number>?,
        textColor: UsedAs<Color3>?,
        strokeColor: UsedAs<Color3>?,
        strokeThickness: UsedAs<number>?,
        cornerRadius: UsedAs<UDim>?,
        zIndex: UsedAs<number>?,
        onActivated: (() -> ())?,
        parent: UsedAs<GuiObject>?
    }
): Frame
    -- Create a state value for rotation
    local rotationValue = scope:Value(0)

    -- Rotation anim
    local function startSpinLoop()
        task.spawn(function()
            while peek(props.visible) do
                rotationValue:set(peek(rotationValue) + 359)
                task.wait(1)
            end
        end)
    end

    -- Start immediately if already visible
    if peek(props.visible) then
        startSpinLoop()
    end

    -- Re-start on future visibility changes
    scope:Observer(props.visible):onChange(function()
        if peek(props.visible) then
            startSpinLoop()
        end
    end)

    -- Rotation animation tween
    local rotationTween = scope:Tween(rotationValue, TweenInfo.new(1, Enum.EasingStyle.Cubic))

    local loadingScreen = scope:New "Frame" {
        Name = props.name or "LoadingFrame",
        Visible = props.visible or true,
        AnchorPoint = props.anchorPoint or Vector2.new(0.5,0.5),
        Position = props.position or UDim2.fromScale(0.5,0.5),
        Size = props.size or UDim2.fromScale(0.3, 0.3),
        BackgroundTransparency = props.backgroundTransparency or 1,
        BackgroundColor3 = props.backgroundColor or UI_CONSTANTS.COLOUR_WHITE,
        ZIndex = props.zIndex or 3,
        Parent = props.parent,
        Active = props.active or true,

        [Children] = {
            scope:New "UICorner" {
                CornerRadius = props.cornered and UDim.new(0.00, 0) or UDim.new(0.05,0) 
            },
            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder
            },

            scope:New "Frame" {
                Name = "Buffer",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromScale(1, 1/3),
                LayoutOrder = 1,
                BackgroundTransparency = 1
            },

            scope:New "Frame" {
                Name = "LoadingContainer",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromScale(1, 1/3),
                LayoutOrder = 2,

                [Children] = {
                    scope:New "UIListLayout" {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0.02,0),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    },

                    scope:New "TextLabel" {
                        Name = "LoadingLabel",
                        Size = UDim2.fromScale(0.5, 1),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        LayoutOrder = 0,
                        Text = "Loading...",
                        TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                        TextStrokeTransparency = 1,
                        BackgroundTransparency = 1,
                        TextScaled = true,
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
                    },
                    scope:New "Frame" {
                        Name = "loadingIconContainer",
                        Size = UDim2.fromScale(0.2,1),
                        AnchorPoint = Vector2.new(0.5,0.5),
                        BackgroundTransparency = 1,
                        LayoutOrder = 1,

                        [Children] = {
                            scope:New "ImageLabel" {
                                Name = "LoadingIcon",
                                Size = UDim2.fromScale(1,1),
                                AnchorPoint = Vector2.new(0.5,0.5),
                                Position = UDim2.fromScale(0.5,0.5),
                                BackgroundTransparency = 1,
                                ImageColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                LayoutOrder = 1,
                                Image = "rbxassetid://96217797477627",
                                Rotation = rotationTween ,

                                [Children] = {
                                    scope:New "UIAspectRatioConstraint" {
                                        AspectRatio = 1
                                    }
                                }
                            }
                        }
                    } 
                }
            },

            scope:New "Frame" {
                Name = "LoadingTextContainer",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromScale(1, 1/3),
                LayoutOrder = 3,
                [Children] = {
                    scope:New "TextLabel" {
                        Name = "LoadingTextLabel",
                        Size = UDim2.fromScale(0.5, 1),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        LayoutOrder = 0,
                        Text = props.text or "",
                        TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                        TextStrokeTransparency = 1,
                        BackgroundTransparency = 1,
                        TextScaled = true,
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
                    },
                }
            },




        }
    } :: Frame
    
    return loadingScreen
end

return Frame