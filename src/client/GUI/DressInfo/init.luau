--!strict

-- Services
local ReplicatedStorage     = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local ImageUris             = require(ReplicatedStorage.DataTables.ImageUris)
local CONFIGURATION_NAMES   = require(ReplicatedStorage.Libraries.GuiManager.CONFIGURATION_NAMES)
local GuiManager            = require(ReplicatedStorage.Libraries.GuiManager.GuiManager)
local CloseButton           = require(ReplicatedStorage.UI.FusionComponents.Widgets.CloseButton)
local Fusion                = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS          = require(Utility:WaitForChild("UI_CONSTANTS"))


-- Fusion Modules
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

--

local function DressPop(scope: Fusion.Scope)
    local closeButton, toggled = CloseButton(scope, {
        onClick = function()
            GuiManager.PopCentre()
        end,
        position = UDim2.fromScale(1.03, 0),
        anchorPoint = Vector2.new(1,0)
    })

    local ftuePop = scope:New "Frame" {
        Name = "DressPop",
        Size = UDim2.fromScale(0.5,0.4),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0.3,
        
        [Children] = {
            closeButton,
            scope: New "UICorner" {
                CornerRadius = UDim.new(0.1,0)
            },
            scope:New "UIStroke" {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Thickness = 3,
                Color = UI_CONSTANTS.TASTEMAKER_PURPLE
            },
            
            scope:New "Frame" {
                Name = "DressInfoTextFrame",
                Size = UDim2.fromScale(1,0.8),
                Position = UDim2.fromScale(0,0.2),
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "TextLabel" {
                        Name = "Header",
                        Size = UDim2.fromScale(1,0.1),
                        BackgroundTransparency = 1,
                        Text = "Go to each catalog station to build your fit.",
                        TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
                        TextScaled = true,
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                    }
                }
            }
         }
    } :: Frame

    return ftuePop
end

return DressPop