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
        end,
        position = UDim2.fromScale(1, 0),
        anchorPoint = Vector2.new(1,0)
    })

    local ftuePop = scope:New "Frame" {
        Name = "FtuePop",
        Size = UDim2.fromScale(1, 1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0,
        
        [Children] = {
            closeButton
        }

    } :: Frame

    return ftuePop
end

return FtuePop