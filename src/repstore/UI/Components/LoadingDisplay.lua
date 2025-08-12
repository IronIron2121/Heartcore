--!strict

--[[
	LoadingDisplay - This functions acts as a basic UI component, implementing a loading spinner.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local loadingDisplayTemplate = ReplicatedStorage.UI.Objects.LoadingDisplay

local ROTATE_TIME = 0.6
local SPIN_INFO = TweenInfo.new(ROTATE_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge)

local function LoadingDisplay(): Frame
	local loadingDisplay = loadingDisplayTemplate:Clone()

	-- Make the spinner spin
	local spinTween = TweenService:Create(loadingDisplay.SpinnerLabel, SPIN_INFO, { Rotation = 360 })
	spinTween:Play()

	loadingDisplay.Destroying:Once(function()
		spinTween:Cancel()
	end)

	return loadingDisplay
end

return LoadingDisplay
