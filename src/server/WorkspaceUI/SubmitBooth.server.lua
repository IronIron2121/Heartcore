--!strict

-- Folders
local submissionZone = workspace:WaitForChild("submissionZone")
local centralPond = workspace:WaitForChild("centralPond")

-- Instances
local submissionHut = submissionZone.submissionHut
local guiFrame = submissionHut.guiFrame
local surfaceGui = guiFrame.SurfaceGui
local timerLabel = surfaceGui.TimerLabel :: TextLabel


local centralPondModel = centralPond.centralPond
local SubmissionBillboardHolder = centralPondModel.SubmissionBillboardHolder
local BillboardGui = SubmissionBillboardHolder.BillboardGui
local Frame = BillboardGui.Frame
local TimeLabel = Frame.TimeLabel :: TextLabel

task.spawn(function()
    while true do
        task.wait(1)
        timerLabel.Text = TimeLabel.Text
    end
end)