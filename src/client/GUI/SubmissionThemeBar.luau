--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility   = ReplicatedStorage:WaitForChild("Utility")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")

-- Modules
local ImageUris = require(ReplicatedStorage.DataTables.ImageUris)
local peek = require(ReplicatedStorage.Utility.Fusion.State.peek)
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))
local GameStateValues = require(Libraries:WaitForChild("GameStateValues"))

-- Fusion 
local Fusion   = require(Utility:WaitForChild("Fusion"))
local scope    = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- State Variables
local timeBound = 30
local labelSize = scope:Value(UDim2.fromScale(1, 0.5))
local labelPosition = scope:Value(UDim2.fromScale(0,0))

local highlightColor = "<font color=\"rgb(92, 95, 212)\">"
local strokeColor = "<stroke color=\"#FFFFFF\">"
local closeStroke = "</stroke>"
local closeFont = "</font>"

local TimeColor = scope:Computed(function(use)
    return use(GameStateValues.secondsRemaining) > timeBound
        and "<font color=\"rgb(89, 247, 128)\">"
        or "<font color=\"rgb(255, 50, 50)\">"
end)

SecondsRemaining:GetPropertyChangedSignal("Value"):Connect(function(...)
    TimeLeft:set(SecondsRemaining.Value)
    if CurrentStateName.Value == "Dressing" then
        ThemeText:set("Fit Check theme: " .. peek(highlightColor) .. peek(strokeColor) .. CurrentThemeName.Value .. peek(closeStroke) .. "</font>" .. ". <br> You have " .. peek(TimeColor) .. SecondsRemaining.Value .. "</font> seconds to submit! </br>")
        labelSize:set(UDim2.fromScale(1, 0.5))
        labelPosition:set(UDim2.fromScale(0,0))
    elseif CurrentStateName.Value == "Voting" then
        ThemeText:set("Voting time! You have " .. peek(TimeColor) .. SecondsRemaining.Value .. "</font> seconds to vote.")
        labelSize:set(UDim2.fromScale(1, 0.3))
        labelPosition:set(UDim2.fromScale(0,0.1))
    elseif CurrentStateName.Value == "Intermission" then
        ThemeText:set("Intermission: " .. peek(TimeColor) .. SecondsRemaining.Value .. "</font>")
        labelSize:set(UDim2.fromScale(1, 0.3))
        labelPosition:set(UDim2.fromScale(0,0.1))
    else
        warn("Unexpected state:", state)
        return "Loading..."
    end
end)

	
local function SubmissionThemeBar()
	local submissionThemeBar = scope:New "Frame" {
        Name = "Container",
        Size = UDim2.fromScale(1, 0.7),
        Position = UDim2.fromScale(0,0),
        BackgroundTransparency = 1,
        BackgroundColor3 = Color3.fromRGB(218, 35, 35),

        [Children] = {
            scope:New "UIListLayout"{
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            },

            scope:New "UIPadding" {
                PaddingTop = UDim.new(0.07, 0),
            },
            
            scope:New "TextLabel" {
                Name = "ThemeText",
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
                RichText = true,
                Text = ThemeText,
                Size = UDim2.fromScale(1, 0.2),
                TextScaled = true,
                LayoutOrder = 0,
                BackgroundTransparency = 1,

                [Children] = {
                    scope:New "TextLabel" {
                        Name = "ThemeText",
                        FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                        RichText = true,
                        Text = ThemeText,
                        Size = labelSize,
                        Position = labelPosition,
                        TextScaled = true,
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                        ZIndex = 2,

                        [Children] = {
                            scope:New "UIStroke"{
                                Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
                                Thickness = 2,
                            }
                        }
                    }
                }
            },
            
            scope:New "ImageLabel" {
                Name = "topBarBG",
                Image = ImageUris.TopBarBG,
                Size = UDim2.fromScale(0.8,0.6),
                Position = UDim2.fromScale(0.1,0.05),
                BackgroundTransparency = 1,
                ZIndex = 0
            }
        }   
    } :: Frame

    return submissionThemeBar
end

return SubmissionThemeBar