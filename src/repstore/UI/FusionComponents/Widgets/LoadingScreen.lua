--!strict
-- LoadingScreen.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    local loadingScreen = scope:New "Frame" {
        Name = "LoadingFrame",
        AnchorPoint = Vector2.new(0.5,0.5),
        Size = props.size or UDim2.fromScale(0.3, 0.3),
        BackgroundTransparency = props.backgroundTransparency or 1,
        BackgroundColor3 = props.backgroundColor or UI_CONSTANTS.COLOUR_WHITE,

        [Children] = {
            scope: New "UICorner" {
                CornerRadius = UDim.new(0.3,0)
            },

            scope:New "UIListLayout" {
                
            }

            scope: New "TextLabel" {
                Name = "Loading",
                Size = UDim2.fromScale(0.5, 0.2),
                AnchorPoint = Vector2.new(0.5,0.5),

            }
        }
    }