--!strict
--[[
-- Services
local TweenService  = game:GetService("TweenService")

-- Folders
local labelStores       = workspace:WaitForChild("LabelStores")
local capitol           = labelStores:WaitForChild("capitol")
local arrowUp           = capitol:WaitForChild("arrowUp")
local arrowDown         = capitol:WaitForChild("arrowDown")

-- Arrow up positions
local positionUp1 = CFrame.new(290.749, 115.278, 335.345)
local positionUp2 = CFrame.new(290.749, 119.778, 335.345)

-- Arrow down positions
local positionDown1 = CFrame.new(237.254, 184.26, 344.627)
local positionDown2 = CFrame.new(237.254, 187.76, 344.627)


local tweenSpeed = 0.7

local tweenInfo = TweenInfo.new(tweenSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)

-- Arrow up anim settings
local upTween1 = TweenService:Create(arrowUp, tweenInfo, {CFrame = positionUp2})
local downTween1 = TweenService:Create(arrowUp, tweenInfo, {CFrame = positionUp1})

-- Arrow down anim settings
local upTween2 = TweenService:Create(arrowDown, tweenInfo, {CFrame = positionDown2})
local downTween2 = TweenService:Create(arrowDown, tweenInfo, {CFrame = positionDown1})

-- Arrow up anim play
task.spawn(function()
    while true do 
        upTween1:Play()
        upTween1.Completed:Wait()
        downTween1:Play()
        downTween1.Completed:Wait()
    end
end) 

-- Arrow down anim play
task.spawn(function()
    while true do 
        upTween2:Play()
        upTween2.Completed:Wait()
        downTween2:Play()
        downTween2.Completed:Wait()
    end
end) 

]]