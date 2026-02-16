--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Instances
local localPlayer = Players.LocalPlayer

-- GUI
local PlayerGui = localPlayer:WaitForChild("PlayerGui")

-- Modules
local ImageUris = require(ReplicatedStorage.DataTables.ImageUris)
local CONFIGURATION_NAMES = require(ReplicatedStorage.Libraries.GuiManager.CONFIGURATION_NAMES)
local GuiManager = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local CloseButton = require(ReplicatedStorage.UI.FusionComponents.Widgets.CloseButton)
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Fusion Modules
local scope = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

--

local function FtuePop(scope: Fusion.Scope)
    local closeButton, toggled = CloseButton(scope, {
        onClick = function()
            GuiManager.PopCentre()
            GuiManager.DisplayConfiguration(CONFIGURATION_NAMES.GameLoopConfig)
        end,
        position = UDim2.fromScale(1.03, 0),
        anchorPoint = Vector2.new(1,0)
    })

    local ftuePop = scope:New "Frame" {
        Name = "FtuePop",
        Size = UDim2.fromScale(0.3,0.7),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0.3,
        
        [Children] = {
            closeButton,
            scope: New "UICorner" {
                CornerRadius = UDim.new(0.1,0)
            },
            scope:New "Frame"{
                Name = "TopBar",
                Size = UDim2.fromScale(1,0.2),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "ImageLabel" {
                        Name = "Logo",
                        AnchorPoint = Vector2.new(0.5,0.5),
                        Size = UDim2.fromScale(1,1),
                        Position = UDim2.fromScale(0.5,0.5),
                        Image = ImageUris.TastemakerLogo,
                        BackgroundTransparency = 1,

                        [Children] = {
                            scope:New "UIAspectRatioConstraint" {
                                AspectRatio = 1
                            }
                        }
                    }
                }
            },
            scope:New "Frame" {
                Name = "FTUETextFrame",
                Size = UDim2.fromScale(1,0.8),
                Position = UDim2.fromScale(0,0.2),
                BackgroundTransparency = 1,
            }
        }

    } :: Frame

    return ftuePop
end

return FtuePop