-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
-- local PlayerGui = localPlayer.PlayerGui
local PlayerGui = localPlayer:WaitForChild("PlayerGui")


-- Modules
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion Modules
local scope = Fusion:scoped()
local OnEvent = Fusion.OnEvent
local peek = Fusion.peek
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- Remotes / Bindables
local PlayerRequestedCurrentTheme = Remotes:WaitForChild("PlayerRequestedCurrentTheme")

local SubmissionGuiController = {}

local currentTheme = scope:Value("")


function SubmissionGuiController.Initialise(
    SubmissionGuiVisible: UsedAs<boolean>,
    TimeText: UsedAs<string>
)

    currentTheme:set(PlayerRequestedCurrentTheme:InvokeServer())


    local _SubmisionGui = scope:New "ScreenGui" {
        Name = "SubmissionGui",
        Enabled = true,
        Parent = PlayerGui,

        [Children] = {
            scope:New "Frame"{
                Name = "Container",
                Size = UDim2.fromScale(1,0.2),
                Position = UDim2.fromScale(0,0),
                BackgroundTransparency = 0,
                Visible = true,

                [Children] = {
                    scope:New "TextLabel" {
                        Name = "SubmissionGui",
                        Text = scope:Computed(function()
                            return "Current Fit Check theme: " .. (currentTheme:get() or "Unknown")
                        end),
                        TextScaled = true,
                        Size = UDim2.fromScale(0.4, 1),
                        AnchorPoint = Vector2.new(0.5,0.5),
                        Position = UDim2.fromScale(0.5,0.5),
                        TextColor3 = Color3.fromRGB(92, 96, 214),
                        BackgroundTransparency = 0
                    }
                }
            }
        }
    }
end

return SubmissionGuiController

