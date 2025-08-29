--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Folders
local Controllers = ReplicatedStorage:WaitForChild("Controllers")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Modules
local ThemeManager = require(Controllers:WaitForChild("ContestManager"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion
local scope = Fusion:scoped()
local Children = Fusion.Children

-- Local Player
local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer.PlayerGui

-- Remotes Events
local ThemeChanged = Remotes:WaitForChild("ThemeChanged")

-- Variables
local CurrentTheme = scope:Value(ThemeManager:getThemeName())
--

local function initTestGui()
    local TestGui = scope:New "ScreenGui" {
        Parent = PlayerGui,
        Name = "TestGui",
        Enabled = true,

        [Children] = {
            scope:New "TextLabel" {
                Name = "Countdown",
                Text = "Countdown to go here",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromScale(0.2, 0.1),
                Position = UDim2.fromScale(0.25, 0.8)
            },

            scope:New "TextLabel" {
                Name = "CurrentTheme",
                Text = CurrentTheme,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromScale(0.2, 0.1),
                Position = UDim2.fromScale(0.75, 0.8)            
            }
        }
    }
end

initTestGui()

ThemeChanged.OnClientEvent:Connect(function(newTheme)
    CurrentTheme:set(newTheme.Theme)
end)

UserInputService.InputBegan:Connect(function(inputObject, processed)
    --print(inputObject.KeyCode)
end)