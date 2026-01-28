--!strict
-- LoadingScreen.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Fusion
local Children = Fusion.Children
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
    }
): Frame

    -- Create a Value to track rotation
    local rotationValue = scope:Value(0)
    
    -- Create a spring animation for smooth rotation
    local rotationSpring = scope:Spring(rotationValue:, 25, 1)
    
    -- Continuously update rotation
    local rotationConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
        rotationValue:set((rotationValue:get(false) + deltaTime * 180) % 360)
    end)
    
    -- Clean up connection when scope is destroyed
    table.insert(scope, rotationConnection)

    local loadingScreen = scope:New "Frame" {
        Name = props.name or "LoadingFrame",
        Visible = props.visible or true,
        AnchorPoint = props.anchorPoint or Vector2.new(0.5,0.5),
        Position = props.position or UDim2.fromScale(0.5,0.5),
        Size = props.size or UDim2.fromScale(0.3, 0.3),
        BackgroundTransparency = props.backgroundTransparency or 1,
        BackgroundColor3 = props.backgroundColor or UI_CONSTANTS.COLOUR_WHITE,
        ZIndex = props.zIndex or 3,

        [Children] = {
            scope:New "UICorner" {
                CornerRadius = UDim.new(0.3,0)
            },

            scope:New "UIListLayout" {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0.02,0),
                SortOrder = Enum.SortOrder.LayoutOrder
            },

            scope:New "TextLabel" {
                Name = "LoadingLabel",
                Size = UDim2.fromScale(0.5, 0.2),
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.fromScale(0.5,0.5),
                LayoutOrder = 0,
                Text = "Loading...",
                TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                TextStrokeTransparency = 1,
                BackgroundTransparency = 1,
                TextScaled = true,
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular)
            },

            scope:New "ImageLabel" {
                Name = "LoadingIcon",
                Size = UDim2.fromScale(0.2,0.2),
                AnchorPoint = Vector2.new(0.5,0.5),
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Image = "rbxassetid://96217797477627",
                Rotation = rotationSpring
            }
        }
    } :: Frame
    
    return loadingScreen
end

return Frame