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

local timerCount = scope:Value(0)

local timerColor = scope:Computed(function(use)
	return use(timerCount) <= 3
		and Color3.fromRGB(255, 80, 80)
		or  Color3.fromRGB(255, 255, 255)
end)

local timerText = scope:Computed(function(use)
	return tostring(use(timerCount))
end)

-- ─── Timer Frame ─────────────────────────────────────────────────────────────
-- Sized to sit neatly inside the topMiddle GuiConfiguration slot (0.5 x 0.2 of screen)

local frame = scope:New "Frame" {
	Name                   = "ArenaTimerHud",
	Size                   = UDim2.fromScale(0.25, 0.8),
	AnchorPoint            = Vector2.new(0.5, 0.5),
	Position               = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3       = Color3.fromRGB(20, 20, 20),
	BackgroundTransparency = 0.35,

	[Children] = {
		scope:New "UICorner" {
			CornerRadius = UDim.new(0.25, 0),
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
	timerCount:set(duration)
end

return {
	frame    = frame,
	setTimer = setTimer,
}
