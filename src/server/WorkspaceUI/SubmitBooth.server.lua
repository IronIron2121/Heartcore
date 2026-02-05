--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local submissionZone = workspace:WaitForChild("submissionZone")
local centralPond = workspace:WaitForChild("centralPond")
local Values = ReplicatedStorage:WaitForChild("Values")

-- Values
local currentStateName = Values:WaitForChild("CurrentStateName")
local secondsRemaining = Values:WaitForChild("SecondsRemaining")

-- Instances
local submissionHut = submissionZone.submissionHut
local guiFrame = submissionHut.guiFrame
local surfaceGui = guiFrame.SurfaceGui
local timerLabel = surfaceGui.TimerLabel :: TextLabel

secondsRemaining:GetPropertyChangedSignal("Value"):Connect(function(...)  
    if currentStateName.Value == "Dressing" then
        timerLabel.Text = secondsRemaining.Value
    else
        timerLabel.Text = "Waiting..."
    end
end)                                        