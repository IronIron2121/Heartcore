--!strict

local TweenService =    game:GetService("TweenService")

local labelStores = workspace:WaitForChild("LabelStores")
local capitol = labelStores:WaitForChild("capitol")
local arrowController = capitol:WaitForChild("arrowUp")

local position1 = CFrame.new(290.749, 115.278, 335.345)
local position2 = CFrame.new(290.749, 119.778, 335.345)
local tweenSpeed = 0.7

local tweenInfo = TweenInfo.new(tweenSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)

local upTween = TweenService:Create(arrowController, tweenInfo, {CFrame = position2})
local downTween = TweenService:Create(arrowController, tweenInfo, {CFrame = position1})

task.spawn(function()
    while true do 
        upTween:Play()
        upTween.Completed:Wait()
        downTween:Play()
        downTween.Completed:Wait()
    end
end) 