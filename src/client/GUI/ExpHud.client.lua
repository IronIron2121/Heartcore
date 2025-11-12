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

-- Fusion Modules
local scope = Fusion:scoped()
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

-- GUI
local PlayerGui = localPlayer.PlayerGui
local ExpBar = require(FusionComponents:WaitForChild("ExpBar"))


local leaderstats = localPlayer:WaitForChild("leaderstats")
local level = leaderstats:WaitForChild("Level")
local levelName = leaderstats:WaitForChild("LevelName")

local rankText = Fusion.Value(scope, levelName.Value)


levelName:GetPropertyChangedSignal("Value"):Connect(function()
    rankText:set(levelName.Value .. " (Lv. " .. level.Value .. ")")
end)

local function animateLevelName(label)
	
	-- Store original properties
	local originalSize = label.Size
	local originalPosition = label.Position
	
	-- --- 1. Size "Pop" Animation ---
	
	-- How big it will pop (1.3x its original scale)
	local popSize = UDim2.new(
		originalSize.X.Scale * 1.3, originalSize.X.Offset,
		originalSize.Y.Scale * 1.3, originalSize.Y.Offset
	)
	
	-- Animation settings
	-- Using "Back" EasingStyle gives it a nice "pop" or "overshoot" effect
	local popInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local returnInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	
	-- Create the tweens
	local tweenPop = TweenService:Create(label, popInfo, {Size = popSize})
	local tweenReturn = TweenService:Create(label, returnInfo, {Size = originalSize})
	
	-- Play the pop
	tweenPop:Play()
	tweenPop.Completed:Wait() -- Wait for it to finish popping
	
	-- Play the return to normal size
	tweenReturn:Play()
	tweenReturn.Completed:Wait() -- Wait for it to return
	
	-- --- 2. Shake Animation ---
	
	local SHAKE_INTENSITY = 5 -- How many pixels it will shake
	local SHAKE_DURATION = 0.25 -- How long it will shake
	
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
	
	-- --- 3. Reset ---
	-- Always reset to the original position to stop the shake
	label.Position = originalPosition
end

local function initialiseGUI()
	local screenGUI = scope:New "ScreenGui" {
		Parent = PlayerGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
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
                    scope:New "TextLabel" {
                        Name = "playerRankDisplay",
                        Size = UDim2.fromScale(1, 1),
                        Position = UDim2.fromScale(0,0),
                        BackgroundTransparency = 1,
                        Text = rankText,
                        TextColor3 = Color3.new(1,1,1),
                        TextStrokeColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
                        TextStrokeTransparency = 0,
			            FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold, Enum.FontStyle.Normal),
                        TextScaled = true,
                        TextXAlignment = "Left",
                        TextYAlignment = "Top"
                    }
                }
            }
        }
    }
end

initialiseGUI()