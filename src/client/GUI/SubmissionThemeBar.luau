--!strict

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility   = ReplicatedStorage:WaitForChild("Utility")
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
-- Modules
local ImageUris = require(ReplicatedStorage.DataTables.ImageUris)
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))
local GameStateValues = require(Libraries:WaitForChild("GameStateValues"))

-- Fusion
local Fusion   = require(Utility:WaitForChild("Fusion"))
local scope    = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- State Variables
local timeBound = 30

local playerCount = scope:Value(#Players:GetPlayers())
Players.PlayerAdded:Connect(function()
    playerCount:set(#Players:GetPlayers())
end)
Players.PlayerRemoving:Connect(function()
    task.defer(function()
        playerCount:set(#Players:GetPlayers())
    end)
end)

local highlightColor = "<font color=\"rgb(92, 95, 212)\">"
local strokeColor = "<stroke color=\"#FFFFFF\">"
local closeStroke = "</stroke>"
local closeFont = "</font>"

local TimeColor = scope:Computed(function(use)
    return use(GameStateValues.secondsRemaining) > timeBound
        and "<font color=\"rgb(89, 247, 128)\">"
        or "<font color=\"rgb(255, 50, 50)\">"
end)

local labelSize = scope:Computed(function(use)
    local state = use(GameStateValues.stateName)

    if state == "Dressing" or state == "Waiting" then
        return UDim2.fromScale(1, 0.9)
    elseif state == "Voting" or state == "Intermission" then
        return UDim2.fromScale(1, 0.5)
    else
        return UDim2.fromScale(1, 0.7) -- default
    end
end)

local labelPosition = scope:Computed(function(use)
    local state = use(GameStateValues.stateName)
    
    if state == "Dressing" then
        return UDim2.fromScale(0.5, 0.5)
    elseif state == "Voting" or state == "Intermission" then
        return UDim2.fromScale(0.5, 0.5)
    else
        return UDim2.fromScale(0.5, 0.5) -- default
    end
end)

local ThemeText = scope:Computed(function(use)
    local state = use(GameStateValues.stateName)
    local theme = use(GameStateValues.themeName)
    local seconds = use(GameStateValues.secondsRemaining)
    local timeColorStr = use(TimeColor)

    if state == "Waiting" then
        return "Waiting for players... (" .. use(playerCount) .. "/3)"
    elseif state == "Dressing" then
        return "Go to each catalog station to build your fit.<br>Theme: " .. highlightColor .. strokeColor .. theme .. closeStroke .. closeFont .. "</br><br>Time left: " .. timeColorStr .. seconds .. closeFont .. "</br>"
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
        Size = UDim2.fromScale(1, 0.4),
        Position = UDim2.fromScale(0,0.01),
        BackgroundTransparency = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),

        [Children] = {

            scope:New "UIGradient" {
			Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.35),
				NumberSequenceKeypoint.new(0.5, 0.2),
				NumberSequenceKeypoint.new(0.8, 0.35),
				NumberSequenceKeypoint.new(1, 1)
			}
		},
            
            scope:New "TextLabel" {
                Name = "ThemeText",
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                RichText = true,
                Text = ThemeText,
                AnchorPoint = Vector2.new(0.5,0.5),
                Size = labelSize,
                Position = labelPosition,
                TextScaled = true,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex = 2,

                [Children] = {
                    scope:New "UIStroke"{
                        Color = UI_CONSTANTS.TASTEMAKER_PURPLE,
                        Thickness = 1,
                    }
                }
            },
        }   
    } :: Frame

    return submissionThemeBar
end

return SubmissionThemeBar