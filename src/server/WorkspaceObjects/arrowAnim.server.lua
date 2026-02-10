--!strict

--[[
local TweenService =    game:GetService("TweenService")

local arrowController = workspace:WaitForChild("submissionZone").ArrowController

local position1 = CFrame.new(-65.368, 26.022, 12.458)
local position2 = CFrame.new(-65.368, 31.022, 12.458)
local tweenSpeed = 0.7

local tweenInfo = TweenInfo.new(tweenSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)

local upTween = TweenService:Create(arrowController.PrimaryPart, tweenInfo, {CFrame = position2})
local downTween = TweenService:Create(arrowController.PrimaryPart, tweenInfo, {CFrame = position1})

task.spawn(function()
    while true do 
        upTween:Play()
        upTween.Completed:Wait()
        downTween:Play()
        downTween.Completed:Wait()
    end
end) 
]]