-- !strict


-- Services
local ReplicatedStorage =   game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion =      require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))


-- Fusion Modules
local scope =       Fusion:scoped()
local Children =    Fusion.Children
type UsedAs<T> =    Fusion.UsedAs<T>

-- Instances
local lobby =  workspace:WaitForChild("lobby")
local fitCheckInfo = lobby.fitCheckInfo
local signHolder = fitCheckInfo.signHolder


local BR = "<br></br>"
local DOUBLE_BR = BR .. BR
local BOLD_OPEN = "<b><font size='60'>"
local BOLD_CLOSE = "</font></b>"
local BODY_OPEN = "<font size='40'>"
local BODY_CLOSE = "</font>"

local surfaceGui = scope:New "SurfaceGui" {
    Face = Enum.NormalId.Left,
    LightInfluence = 0,
    Brightness = 1.5,
    Adornee = signHolder,

    [Children] = {
        scope:New "TextLabel" {
            Name = "fitCheckInfo",
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            TextScaled = false,
            TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
            FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
            TextStrokeColor3 = UI_CONSTANTS.COLOUR_WHITE,
            TextStrokeTransparency = 0,
            RichText = true,
            Text = BOLD_OPEN .. "1. Create a fit" .. BOLD_CLOSE
                .. BR
                .. BODY_OPEN .. "Submit a look that matches the theme." .. BODY_CLOSE
                .. DOUBLE_BR
                .. BOLD_OPEN .. "2. Vote for fits" .. BOLD_CLOSE
                .. BR
                .. BODY_OPEN .. "Vote for your fave fit." .. BODY_CLOSE
                .. DOUBLE_BR
                .. BOLD_OPEN .. "3. Become a Tastemaker" .. BOLD_CLOSE
                .. BR
                .. BODY_OPEN .. "Get votes, rank up, earn status." .. BODY_CLOSE
        }
    }
}

surfaceGui.Parent = signHolder