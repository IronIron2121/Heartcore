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
            TextScaled = true,
            TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
            FontFace = UI_CONSTANTS.DEFAULT_FONT,
            RichText = true,
            Text = "<b>Create a fit</b><br>Build and submit a look that matches the theme.</br><br><b>Vote for fits</b></br><br>Vote for your fave fit.</br><br><b>Become a Tastemaker</b></br><br>Get votes, rank up, earn status.</br>"
        }
    }
}

surfaceGui.parent = signHolder