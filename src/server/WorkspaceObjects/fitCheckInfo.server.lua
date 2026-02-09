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
local signHolder =  workspace:WaitForChild("fitCheckInfo").signHolder

local surfaceGui = scope:New "SurfaceGui" {
    Face = Enum.NormalId.Left,
    LightInfluence = 0,
    Adornee = signHolder,

    [Children] = {
        scope:New "TextLabel" {
            Name = "fitCheckInfo",
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            TextScaled = false,
            TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
            FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
            RichText = true,
            Text = "<b><font size='60'>1. Create a fit</font></b><br></br><br><font size='40'>Submit a look that matches the theme.</font></br><br></br><br></br><br><b><font size='60'>2. Vote for fits</font></b><br></br></br><br><font size='40'>Vote for your fave fit.</font></br><br></br><br></br><br><b><font size='60'>3. Become a Tastemaker</font></b></br><br></br><br><font size='40'>Get votes, rank up, earn status.</font></br>"
        }
    }
}

surfaceGui.Parent = signHolder