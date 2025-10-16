--!strict
-- Button.lua

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local ImageUris = require(DataTables:WaitForChild("ImageUris"))


-- Fusion
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

function XpBar(
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
		textColor: UsedAs<Color3>?,
		strokeColor: UsedAs<Color3>?,
		strokeThickness: UsedAs<number>?,
		cornerRadius: UsedAs<UDim>?,
		zIndex: UsedAs<number>?,
		onActivated: (() -> ())?,
	}
): ImageLabel

local Container = scope:New "Frame" {
    Name = "XpBarContainer",
    BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 1
}

local XpImage = scope:New "ImageLabel" {
    Name = props.name or "XpBar",
    Active = props.active or true,
    Visible = props.visible or true,
    AnchorPoint = props.anchorPoint or Vector2.new(0.5,0.5),
    Position = props.position or UDim2.fromScale(0.5,0.5),
    Size = props.size or UDim2.fromScale(1,1),
    BackgroundTransparency = 1,
    ZIndex = 2
}