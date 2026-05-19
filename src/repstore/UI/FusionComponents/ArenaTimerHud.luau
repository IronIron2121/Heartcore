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

local timerColor = scope:Computed(function(use)
	return use(timerCount) <= 3
		and Color3.fromRGB(255, 80, 80)
		or  UI_CONSTANTS.TASTEMAKER_PURPLE
end)

local timerText = scope:Computed(function(use)
	return tostring(use(timerCount))
end)

local frameSize = scope:Value(UDim2.fromScale(0.25, 0.8))

-- ─── Timer Frame ─────────────────────────────────────────────────────────────

local frame = scope:New "Frame" {
	Name                   = "ArenaTimerHud",
	Size                   = frameSize,
	AnchorPoint            = Vector2.new(0.5, 0.5),
	Position               = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3       = Color3.fromRGB(255,255,255)
,
	BackgroundTransparency = 0.35,

	[Children] = {
		scope:New "UICorner" {
			CornerRadius = UDim.new(0.1, 0),
		},
		scope:New "UIPadding" {
			PaddingLeft  = UDim.new(0.04, 0),
			PaddingRight = UDim.new(0.04, 0),
		},
		scope:New "UIGradient" {
			Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.25),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.8, 0.25),
				NumberSequenceKeypoint.new(1, 1)
			}
		},

		scope:New "TextLabel" {
			Size                   = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text                   = timerText,
			TextScaled             = true,
			TextColor3             = timerColor,
			FontFace               = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),

			[Children] = {
				scope:New "UIStroke" {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 4,
				}
			}
		},
	},
} :: Frame

-- ─── Public API ──────────────────────────────────────────────────────────────

local function setTimer(duration: number)
	timerCount:set(duration)
end

return {
	frame      = frame,
	setTimer   = setTimer,
}