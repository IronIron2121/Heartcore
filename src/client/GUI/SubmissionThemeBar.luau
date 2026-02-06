--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility   = ReplicatedStorage:WaitForChild("Utility")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")

-- Modules
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))
local GameStateValues = require(Libraries:WaitForChild("GameStateValues"))

-- Instances
local centralPond               = workspace:WaitForChild("centralPond")
local pondModel                 = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = pondModel:WaitForChild("SubmissionBillboardHolder")
local BillboardGui              = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame                     = BillboardGui:WaitForChild("Frame")

-- Fusion 
local Fusion   = require(Utility:WaitForChild("Fusion"))
local scope    = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- State Variables
local timeBound = 30

local highlightColor = "<font color=\"rgb(92, 95, 212)\">"
local strokeColor = "<stroke color=\"#FFFFFF\">"
local closeStroke = "</stroke>"
local closeFont = "</font>"

local TimeColor = scope:Computed(function(use)
    return use(GameStateValues.secondsRemaining) > timeBound
        and "<font color=\"rgb(89, 247, 128)\">"
        or "<font color=\"rgb(255, 50, 50)\">"
end)

local ThemeText = scope:Computed(function(use)
    local state = use(GameStateValues.stateName)
    local theme = use(GameStateValues.themeName)
    local seconds = use(GameStateValues.secondsRemaining)
    local timeColorStr = use(TimeColor)

    if state == "Dressing" then
        return "Current Fit Check theme: " .. highlightColor .. strokeColor .. theme .. closeStroke .. closeFont .. ". You have " .. timeColorStr .. seconds .. closeFont .. " seconds to submit!"
    elseif state == "Voting" then
        return "Voting time! You have " .. timeColorStr .. seconds .. closeFont .. " seconds to vote."
    elseif state == "Intermission" then
        return "Intermission: " .. timeColorStr .. seconds .. closeFont
    else
        warn("Unexpected state:", state)
        return "Loading..."
    end
end)

	
local function SubmissionThemeBar()
	local submissionThemeBar = scope:New "Frame" {
        Name = "Container",
        Size = UDim2.fromScale(1, 1),
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
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                RichText = true,
                Text = ThemeText,
                Size = UDim2.fromScale(1, 0.2),
                TextScaled = true,
                LayoutOrder = 0,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),

                [Children] = {
                    scope:New "UIStroke"{
                        Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
                        Thickness = 2,
                    }
                }
            },
        }   
    } :: Frame

    return submissionThemeBar
end

return SubmissionThemeBar