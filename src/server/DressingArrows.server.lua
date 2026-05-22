--!strict

local TweenService = game:GetService("TweenService")

local arrows = workspace:WaitForChild("DRESSING_ZONE"):WaitForChild("Arrows")

local ANIM_HEIGHT = 2
local ANIM_SPEED = 1.2
local STAGGER_OFFSET = 0.15

local tweenInfoUp = TweenInfo.new(ANIM_SPEED, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local tweenInfoDown = TweenInfo.new(ANIM_SPEED, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function arrowAnim(part, delay)
    local ogPosition = part.Position.Y

    task.delay(delay, function()
        while true do
            local upPosition = {Position = part.Position + Vector3.new(0, ANIM_HEIGHT, 0)}
            local tweenUp = TweenService:Create(part, tweenInfoUp, upPosition)
            tweenUp:Play()
            tweenUp.Completed:Wait()

            local downPosition = {Position = part.Position - Vector3.new(0, ANIM_HEIGHT,0)}
            local tweenDown = TweenService:Create(part, tweenInfoDown, downPosition)
            tweenDown:Play()
            tweenDown.Completed:Wait()
        end
    end)
end

local parts = arrows:GetChildren()
for i, part in ipairs(parts) do
    if part:IsA("BasePart") then
        arrowAnim(part, (i - 1) * STAGGER_OFFSET)
    end
end