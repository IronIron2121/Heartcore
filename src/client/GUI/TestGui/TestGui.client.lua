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
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion
local scope = Fusion:scoped()
local Children = Fusion.Children

-- Local Player
local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer.PlayerGui

-- Remotes Events
local ThemeChanged = Remotes:WaitForChild("ThemeChanged")

-- Integrated ThemeManager (Client-Side)
local ThemeManager = {}
ThemeManager.CurrentTheme = nil

-- Default themes list (for client reference)
ThemeManager.Themes = {
    "Cyberpunk Streetwear",
    "Medieval Knight",
    "Beach Party", 
    "Winter Wonderland",
    "Space Explorer",
    "Royal Ball",
    "Sports Day"
}

-- Events
local themeChangedSignal = Instance.new("BindableEvent")
ThemeManager.ThemeChanged = themeChangedSignal.Event

-- Client-safe functions only
function ThemeManager:getCurrentTheme(): {}?
    return self.CurrentTheme
end

function ThemeManager:getThemeName(): string
    return self.CurrentTheme and self.CurrentTheme.Theme or "Loading..."
end

function ThemeManager:getTimeChanged(): number?
    return self.CurrentTheme and self.CurrentTheme.TimeChanged or nil
end

function ThemeManager:getPhasePrefix(): string?
    return self.CurrentTheme and self.CurrentTheme.PhasePrefix or nil
end

function ThemeManager:getAvailableThemes(): {string}
    return self.Themes
end

-- Handle theme updates from server
local function onThemeChanged(newThemeData: {})
    local oldTheme = ThemeManager.CurrentTheme
    ThemeManager.CurrentTheme = newThemeData
    
    print("Theme updated to:", newThemeData.Theme)
    
    -- Fire the changed signal for UI updates
    themeChangedSignal:Fire(newThemeData, oldTheme)
end

-- Connect to remote event
ThemeChanged.OnClientEvent:Connect(onThemeChanged)

-- Variables
local CurrentTheme = scope:Value(ThemeManager:getThemeName())

-- Connect ThemeManager's signal to update Fusion state
ThemeManager.ThemeChanged:Connect(function(newTheme, oldTheme)
    CurrentTheme:set(newTheme.Theme)
    print("UI updated - Theme changed from", oldTheme and oldTheme.Theme or "none", "to", newTheme.Theme)
end)

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

UserInputService.InputBegan:Connect(function(inputObject, processed)
    --print(inputObject.KeyCode)
end)