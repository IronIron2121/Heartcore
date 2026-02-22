--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility = ReplicatedStorage:WaitForChild("Utility")

-- Modules
local Fusion       = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS = require(Utility:WaitForChild("UI_CONSTANTS"))

local scope    = Fusion:scoped()
local Children = Fusion.Children

-- ─── Reactive state ──────────────────────────────────────────────────────────

local timerCount  = scope:Value(0)
local waitingMode = scope:Value(false)

local timerColor = scope:Computed(function(use)
	if use(waitingMode) then return Color3.fromRGB(255, 255, 255) end
	return use(timerCount) <= 3
		and Color3.fromRGB(255, 80, 80)
		or  Color3.fromRGB(255, 255, 255)
end)

local timerText = scope:Computed(function(use)
	if use(waitingMode) then
		return "Waiting for all players to finish voting..."
	end
	return tostring(use(timerCount))
end)

local frameSize = scope:Computed(function(use)
	return use(waitingMode)
		and UDim2.fromScale(0.9, 0.8)
		or  UDim2.fromScale(0.25, 0.8)
end)

-- ─── Timer Frame ─────────────────────────────────────────────────────────────
-- Sized to sit neatly inside the topMiddle GuiConfiguration slot (0.5 x 0.2 of screen)

local frame = scope:New "Frame" {
	Name                   = "ArenaTimerHud",
	Size                   = frameSize,
	AnchorPoint            = Vector2.new(0.5, 0.5),
	Position               = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3       = Color3.fromRGB(20, 20, 20),
	BackgroundTransparency = 0.35,

	[Children] = {
		scope:New "UICorner" {
			CornerRadius = UDim.new(0.1, 0),
		},
		scope:New "UIPadding" {
			PaddingLeft  = UDim.new(0.04, 0),
			PaddingRight = UDim.new(0.04, 0),
		},
		scope:New "TextLabel" {
			Size                   = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text                   = timerText,
			TextScaled             = true,
			TextColor3             = timerColor,
			FontFace               = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
		},
	},
} :: Frame

-- ─── Public API ──────────────────────────────────────────────────────────────

local function setTimer(duration: number)
	waitingMode:set(false)
	timerCount:set(duration)
end

local function setWaiting()
	waitingMode:set(true)
end

return {
	frame      = frame,
	setTimer   = setTimer,
	setWaiting = setWaiting,
}
