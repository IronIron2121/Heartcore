--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService") 



-- Folders
local UI = ReplicatedStorage:WaitForChild("UI")
local FusionComponents = UI:WaitForChild("FusionComponents")
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))
local Fusion = require(Utility:WaitForChild("Fusion"))

-- Instances
local localPlayer = Players.LocalPlayer
local PlayerGui = localPlayer.PlayerGui


local scope = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI
local ExpBar = require(FusionComponents:WaitForChild("ExpBar"))

local leaderstats = localPlayer:WaitForChild("leaderstats")
local level = leaderstats:WaitForChild("Level")
local Rank = leaderstats:WaitForChild("Rank")

local rankText = Fusion.Value(scope, Rank.Value)

--Anim function
local function animateRank(label)
	
	-- Store original properties
	local originalSize = label.Size
	local originalPosition = label.Position

	
-- Size anim
	local popScale = 3 
	local popSize = UDim2.new(
		originalSize.X.Scale * popScale, originalSize.X.Offset,
		originalSize.Y.Scale * popScale, originalSize.Y.Offset
	)
	
	-- Instantly set the size
	label.Size = popSize

	task.wait(0.3)
	
	local FALL_DURATION = 0.5 
	local fallInfo = TweenInfo.new(
		FALL_DURATION,
		Enum.EasingStyle.Bounce, 
		Enum.EasingDirection.Out
	)
	
	--tween
	local tweenFall = TweenService:Create(label, fallInfo, {Size = originalSize})
	
	tweenFall:Play()
	tweenFall.Completed:Wait()

	-- shake anim	
	local SHAKE_INTENSITY = 5 
	local SHAKE_DURATION = 0.25
	
	local startTime = tick()
	
	while tick() - startTime < SHAKE_DURATION do
		-- Calculate random offsets
		local offsetX = math.random(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		local offsetY = math.random(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		
		-- Apply the offset from the original position
		label.Position = UDim2.new(
			originalPosition.X.Scale, originalPosition.X.Offset + offsetX,
			originalPosition.Y.Scale, originalPosition.Y.Offset + offsetY
		)
		
		task.wait() -- Wait one frame
	end
	
	-- --- 5. Reset ---
	-- Always reset to the original position to stop the shake
	label.Position = originalPosition
end
	


local function initialiseGUI()
	local screenGUI = scope:New "ScreenGui" {
		Parent = PlayerGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Global
	}

	local playerRankLabel = scope:New "TextLabel" {
		Name = "playerRankDisplay",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0,1),
        AnchorPoint = Vector2.new(0,1),
		BackgroundTransparency = 1,
		Text = rankText,
		TextColor3 = Color3.new(1,1,1),
		TextStrokeColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
		TextStrokeTransparency = 0,
		FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextScaled = true,
		TextXAlignment = "Left",
		TextYAlignment = "Top",
        ZIndex = 2
	}
	
	
	
	local _hudTopBar = scope:New "Frame" {
		Size = UDim2.fromScale(1,0.2),
		Position = UDim2.fromScale(0,0.88),
		AnchorPoint = Vector2.new(0,0),
		Parent = screenGUI,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,

		[Children] = {

			scope:New "Frame" {
				Name = "Container",
				Size = UDim2.fromScale(1,1),
				Position = UDim2.fromScale(0,0),
				BackgroundColor3 = Color3.new(0.654902, 0.215686, 0.215686),
				BackgroundTransparency = 1,

				[Children] = {
					ExpBar(scope, {
						name = "ExpBar"
					})
				}
			},

			scope:New "Frame" {
				Name = "rankContainer",
				AnchorPoint = Vector2.new(0,0),
				Size = UDim2.fromScale(0.2, 0.2),
				Position = UDim2.fromScale(0.03,0.3),
				BackgroundTransparency = 1,

				[Children] = {
					playerRankLabel
				}
			}
		}
	}
	
	Rank:GetPropertyChangedSignal("Value"):Connect(function()
		rankText:set(Rank.Value .. " (Lv. " .. level.Value .. ")")

		task.spawn(animateRank, playerRankLabel)
	end)
	
end

initialiseGUI()