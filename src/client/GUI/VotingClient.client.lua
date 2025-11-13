--!strict

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Utility = ReplicatedStorage:WaitForChild("Utility")
local ImageUris = require(ReplicatedStorage.DataTables.ImageUris)
local VotingClientManager = require(Utility:WaitForChild("VotingClientManager"))

-- Player GUI reference
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VoteButtonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Create VoteButton
local button = Instance.new("ImageButton")
button.Name = "VoteButton"
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Position = UDim2.fromScale(0.8, 0.9)
button.Size = UDim2.new(0,100,0,100)
button.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
button.BackgroundTransparency = 1
button.Parent = screenGui
button.Image = "rbxassetid://137550678558366"
button.ImageTransparency = 0


-- Tween info
local clickTweenInfo = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local appearTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Animations
local function playClickAnimation()
	local shrinkTween = TweenService:Create(button, clickTweenInfo, { Size = UDim2.new(0, 180, 0, 45) })
	local growTween = TweenService:Create(button, clickTweenInfo, { Size = UDim2.new(0, 200, 0, 50) })
	shrinkTween:Play()
	shrinkTween.Completed:Wait()
	growTween:Play()
end

local function showButton(visible: boolean)
	if visible then
		button.Visible = true
		button.ImageTransparency = 1
		local appearTween = TweenService:Create(button, appearTweenInfo, {
			ImageTransparency = 0,
		})
		appearTween:Play()
	else
		local disappearTween = TweenService:Create(button, appearTweenInfo, {
			ImageTransparency = 1,
		})
		disappearTween:Play()
		disappearTween.Completed:Wait()
		button.Visible = false
	end
end

-- Click behavior
button.MouseButton1Click:Connect(function()
	playClickAnimation()
	VotingClientManager.onVotePromptActivated()
end)

-- Listen to VoteGui visibility
VotingClientManager.VoteGuiVisible:onChange(function(isVisible: boolean)
	if isVisible then
		showButton(false)
	else
		showButton(true)
	end
end)


-- Initialize Voting GUI controller
VotingClientManager.initialiseVotingGui()

-- Start visible
showButton(true)
