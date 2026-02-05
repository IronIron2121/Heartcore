--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility   = ReplicatedStorage:WaitForChild("Utility")
local Values    = ReplicatedStorage:WaitForChild("Values")   

-- Modules
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))

-- Instances
local centralPond               = workspace:WaitForChild("centralPond")
local pondModel                 = centralPond:WaitForChild("centralPond")
local SubmissionBillboardHolder = pondModel:WaitForChild("SubmissionBillboardHolder")
local BillboardGui              = SubmissionBillboardHolder:WaitForChild("BillboardGui")
local Frame                     = BillboardGui:WaitForChild("Frame")

-- Values
local CurrentThemeName = Values.CurrentThemeName

-- Fusion 
local Fusion   = require(Utility:WaitForChild("Fusion"))
local scope    = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- State Variables
local ThemeText = scope:Value("Loading...")
CurrentThemeName:GetPropertyChangedSignal("Value"):Connect(function(...) 
    ThemeText:set("Current Fit Check theme: <font color=\"rgb(89, 247, 128)\">" .. CurrentThemeName.Value .. "</font>")
end)
ThemeText:set("Current Fit Check theme: <font color=\"rgb(89, 247, 128)\">" .. CurrentThemeName.Value .. "</font>")

	
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

             scope:New "TextLabel" {
                Name = "SubmitText",
                FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT,Enum.FontWeight.Bold),
                Text = "Submit your fit in the submission hut!",
                Size = UDim2.fromScale(1, 0.2),
                TextScaled = true,
                LayoutOrder = 1,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255),

                [Children] = {
                    scope:New "UIStroke" {
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