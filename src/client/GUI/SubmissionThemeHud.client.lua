--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService") 


-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Instances
local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer.PlayerGui


-- Fusion Modules
local scope = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI
local ExpBar = require(FusionComponents:WaitForChild("ExpBar"))


local leaderstats = localPlayer:WaitForChild("leaderstats")
local level = leaderstats:WaitForChild("Level")
local levelName = leaderstats:WaitForChild("LevelName")



	


local function initialiseGUI()
	local screenGUI = scope:New "ScreenGui" {
		Parent = PlayerGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Global
	}

	local frame = scope:New "Frame" {
        Size = UDim2.fromScale(1, 0.3),
        Position = UDim2.fromScale(0,0),
        BackgroundTransparency = 0,
        BackgroundColor3 = Color3.fromRGB(218, 35, 35)
    }
	
end

initialiseGUI()