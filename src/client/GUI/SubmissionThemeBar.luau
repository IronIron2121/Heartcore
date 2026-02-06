--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility   = ReplicatedStorage:WaitForChild("Utility")
local Values    = ReplicatedStorage:WaitForChild("Values")   

-- Modules
local ImageUris = require(ReplicatedStorage.DataTables.ImageUris)
local peek = require(ReplicatedStorage.Utility.Fusion.State.peek)
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Instances
local centralPond               = workspace:WaitForChild("centralPond")
local pondModel                 = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = pondModel:WaitForChild("SubmissionBillboardHolder")
local BillboardGui              = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame                     = BillboardGui:WaitForChild("Frame")

-- Values
local CurrentThemeName = Values.CurrentThemeName
local CurrentStateName = Values.CurrentStateName
local SecondsRemaining = Values.SecondsRemaining

-- Fusion 
local Fusion   = require(Utility:WaitForChild("Fusion"))
local scope    = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- State Variables
local ThemeText = scope:Value("Loading...")
local TimeLeft = scope:Value(SecondsRemaining.Value)
local timeBound = 30
local labelSize = scope:Value(UDim2.fromScale(1, 0.5))
local labelPosition = scope:Value(UDim2.fromScale(0,0))


local highlightColor = scope:Value("<font color=\"rgb(92, 95, 212)\">")
local strokeColor = scope:Value("<stroke color=\"#FFFFFF\">")
local closeStroke = scope:Value("</stroke>")
local TimeColor = scope:Computed(function(use)
    return use(TimeLeft) > timeBound and "<font color=\"rgb(89, 247, 128)\">" or "<font color=\"rgb(255, 50, 50)\">"
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
        warn("This shouldn't be possible", CurrentStateName.Value)
    end
end)

ThemeText:set("Fit Check theme is: <font color=\"rgb(89, 247, 128)\">" .. CurrentThemeName.Value .. "</font>")

	
local function SubmissionThemeBar()
	local submissionThemeBar = scope:New "Frame" {
        Name = "Container",
        Size = UDim2.fromScale(1, 0.7),
        Position = UDim2.fromScale(0,0),
        BackgroundTransparency = 1,
        BackgroundColor3 = Color3.fromRGB(218, 35, 35),

        [Children] = {
            scope:New "Frame" {
                Name = "TextContainer",
                Size = UDim2.fromScale(1,1),
                Position = UDim2.fromScale(0,0.1),
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