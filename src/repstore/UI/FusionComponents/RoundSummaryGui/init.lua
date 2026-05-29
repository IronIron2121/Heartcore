--!strict

-- Services
local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Utility    = ReplicatedStorage:WaitForChild("Utility")
local Libraries  = ReplicatedStorage:WaitForChild("Libraries")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")

-- Modules
local Fusion       = require(Utility.Fusion)
local ExpConfig    = require(Libraries.ExpConfig)
local UI_CONSTANTS = require(Utility.UI_CONSTANTS)
local ImageUris    = require(DataTables.ImageUris)

-- Fusion
local Children = Fusion.Children
type UsedAs<T> = Fusion.UsedAs<T>

--

local ORDINAL_SUFFIX = { [1] = "ST", [2] = "ND", [3] = "RD" }
local function ordinal(n: number): string
	return n .. (ORDINAL_SUFFIX[n] or "TH")
end

local function placementSubtext(placement: number?): string
	if not placement then return "BETTER LUCK NEXT TIME!" end
	if placement == 1 then return "TOP OF THE PODIUM!" end
	if placement <= 3 then return "'ON THE PODIUM!'" end
	if placement <= 20 then return "TOP 20!" end
	return "BETTER LUCK NEXT TIME!"
end

local function makeXpRow(scope: Fusion.Scope, label: string, amount: number): Frame
	return scope:New "Frame" {
		Name = "XpRow",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		[Children] = {
			scope:New "TextLabel" {
				Size = UDim2.fromScale(0.7, 1),
				BackgroundTransparency = 1,
				Text = label,
				TextColor3 = Color3.new(1, 1, 1),
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			scope:New "TextLabel" {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.28, 1),
				BackgroundTransparency = 1,
				Text = "+ " .. amount .. " XP",
				TextColor3 = UI_CONSTANTS.TASTEMAKER_GREEN,
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},
	} :: Frame
end

local function makeChallengeRow(scope: Fusion.Scope, entry: {
	id: string, label: string, progress: number, target: number, xpReward: number
}): Frame
	local fillScale = math.clamp(entry.progress / math.max(entry.target, 1), 0, 1)
	return scope:New "Frame" {
		Name = "ChallengeRow",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Color3.fromRGB(200, 200, 200),
		BackgroundTransparency = 0.6,
		[Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0.2, 0) },
			scope:New "UIPadding" {
				PaddingLeft = UDim.new(0.02, 0), PaddingRight = UDim.new(0.02, 0),
				PaddingTop = UDim.new(0.1, 0), PaddingBottom = UDim.new(0.1, 0),
			},
			scope:New "TextLabel" {
				Size = UDim2.fromScale(0.45, 0.7),
				Position = UDim2.fromScale(0, 0.15),
				BackgroundTransparency = 1,
				Text = string.upper(entry.label),
				TextColor3 = Color3.new(1, 1, 1),
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			scope:New "Frame" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.6, 0.5),
				Size = UDim2.fromScale(0.32, 0.4),
				BackgroundColor3 = Color3.fromRGB(176, 183, 253),
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0.5, 0) },
					scope:New "Frame" {
						Size = UDim2.fromScale(fillScale, 1),
						BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_GREEN,
						[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0.5, 0) } },
					},
				},
			},
			scope:New "TextLabel" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.78, 0.5),
				Size = UDim2.fromScale(0.08, 0.6),
				BackgroundTransparency = 1,
				Text = entry.progress .. "/" .. entry.target,
				TextColor3 = UI_CONSTANTS.COLOUR_WHITE,
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
				TextScaled = true,
			},
			scope:New "TextLabel" {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromScale(0.12, 0.6),
				BackgroundTransparency = 1,
				Text = "◆ " .. entry.xpReward .. " xp",
				TextColor3 = UI_CONSTANTS.TASTEMAKER_GREEN,
				FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},
	} :: Frame
end

-- ─── Module ────────────────────────────────────────────────────────────────────

local RoundSummaryGui = {}

local scope = Fusion:scoped()

local displayXp   = scope:Value(0)
local placement   = scope:Value(nil :: number?)
local xpBreakdown = scope:Value({} :: { { label: string, amount: number } })
local challenges  = scope:Value({} :: { { id: string, label: string, progress: number, target: number, xpReward: number } })

local animXp = scope:Tween(displayXp, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

local currentLevel = scope:Computed(function(use)
	return ExpConfig.getLevelFromExp(math.floor(use(animXp)))
end)

local rankName = scope:Computed(function(use)
	return ExpConfig.getRankName(use(currentLevel))
end)

local barFill = scope:Computed(function(use)
	local xp  = math.floor(use(animXp))
	local lvl = use(currentLevel)
	return ExpConfig.getProgress(xp, lvl)
end)

local xpText = scope:Computed(function(use)
	local xp      = math.floor(use(animXp))
	local lvl     = use(currentLevel)
	local nextLvl = math.min(lvl + 1, 101)
	return xp .. " / " .. ExpConfig.getExpForLevel(nextLvl)
end)

local headingText = scope:Computed(function(use)
	local p = use(placement)
	return p and ("YOU PLACED " .. ordinal(p)) or "NOT PLACED"
end)

local subtextValue = scope:Computed(function(use)
	return placementSubtext(use(placement))
end)

-- ─── Frame ─────────────────────────────────────────────────────────────────────

local xpBreakdownList = scope:New "Frame" {
	Name = "XpBreakdown",
	Size = UDim2.fromScale(1, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	[Children] = {
		scope:New "UIListLayout" {
			Padding = UDim.new(0, 4),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		(scope:ForValues(xpBreakdown, function(use, innerScope: Fusion.Scope, entry: { label: string, amount: number })
			return makeXpRow(innerScope, entry.label, entry.amount)
		end) :: any),
	},
} :: Frame

local challengeList = scope:New "ScrollingFrame" {
	Name = "ChallengeList",
	Size = UDim2.fromScale(1, 1),
	CanvasSize = UDim2.fromScale(0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	BackgroundColor3 = Color3.new(1, 1, 1),
	[Children] = {
		scope:New "UIListLayout" {
			Padding = UDim.new(0, 6),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		(scope:ForValues(challenges, function(use, innerScope: Fusion.Scope, entry)
			return makeChallengeRow(innerScope, entry)
		end) :: any),
	},
} :: ScrollingFrame

local barFillFrame = scope:New "Frame" {
	Name = "Fill",
	Size = scope:Tween(
		scope:Computed(function(use)
			return UDim2.fromScale(use(barFill), 1)
		end),
		TweenInfo.new(0.3)
	),
	BackgroundColor3 = UI_CONSTANTS.TASTEMAKER_GREEN,
	[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0.5, 0) } },
} :: Frame

local gui = scope:New "ScreenGui" {
	Name = "XpSummaryGui",
	IgnoreGuiInset = true,
	DisplayOrder = 208,
	Enabled = false,
	Parent = Players.LocalPlayer.PlayerGui,
} :: ScreenGui

function RoundSummaryGui.hide()
	gui.Enabled = false
end

scope:New "Frame" {
	Name = "RoundSummaryGui",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromScale(0, 0),
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = UI_CONSTANTS.COLOUR_WHITE,
	Parent = gui,
	[Children] = {
		scope:New "UIGradient" {
			Color = ColorSequence.new(
				UI_CONSTANTS.TASTEMAKER_PURPLE,
				Color3.fromRGB(176, 183, 253)
			),
			Rotation = 90
		},
		scope:New "UIPadding" {
			PaddingLeft   = UDim.new(0.05, 0), PaddingRight  = UDim.new(0.05, 0),
			PaddingTop    = UDim.new(0.04, 0), PaddingBottom = UDim.new(0.04, 0),
		},
		scope:New "UIListLayout" {
			Padding = UDim.new(0, 12),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		},

		-- Placement heading
		scope:New "TextLabel" {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
			Text = headingText,
			TextColor3 = Color3.new(1, 1, 1),
			FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
			TextScaled = true,
		},

		-- Subtext
		scope:New "TextLabel" {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			Text = subtextValue,
			TextColor3 = UI_CONSTANTS.TASTEMAKER_PINK,
			FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
			TextScaled = true,
		},

		-- Level + rank label
		scope:New "TextLabel" {
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			Text = scope:Computed(function(use)
				return "Lv. " .. use(currentLevel) .. "  " .. use(rankName)
			end),
			TextColor3 = Color3.new(1, 1, 1),
			FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
			TextScaled = true,
		},

		-- XP bar
		scope:New "Frame" {
			LayoutOrder = 4,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundColor3 = Color3.fromRGB(176, 183, 253),
			[Children] = {
				scope:New "UICorner" { CornerRadius = UDim.new(0.5, 0) },
				barFillFrame,
			},
		},

		-- XP numbers
		scope:New "TextLabel" {
			LayoutOrder = 5,
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text = xpText,
			TextColor3 = UI_CONSTANTS.TASTEMAKER_GREEN,
			FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Regular),
			TextScaled = true,
		},

		-- XP breakdown
		scope:New "Frame" {
			LayoutOrder = 6,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			[Children] = { xpBreakdownList },
		},

		scope:New "Frame" {
			Name = "Buffer",
			LayoutOrder = 7,
			Size = UDim2.fromScale(1, 0.07),
			BackgroundTransparency = 1
		},

		-- Challenge header
		scope:New "TextLabel" {
			LayoutOrder = 7,
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Text = "DAILY CHALLENGES",
			TextColor3 = UI_CONSTANTS.TASTEMAKER_PINK,
			FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		},

		-- Challenge rows
		scope:New "Frame" {
			LayoutOrder = 8,
			Size = UDim2.fromScale(1, 0.4),
			BackgroundTransparency = 1,
			[Children] = { challengeList },
		},

		-- Dismiss button
		scope:New "TextButton" {
			LayoutOrder = 9,
			Size = UDim2.new(0.4, 0, 0, 44),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "CONTINUE",
			TextColor3 = UI_CONSTANTS.TASTEMAKER_PURPLE,
			FontFace = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
			TextScaled = true,
			[Fusion.OnEvent "Activated"] = function()
				RoundSummaryGui.hide()
			end,
			[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0.3, 0) } },
		},
	},
}

function RoundSummaryGui.show(data: {
	placement: number?,
	previousExp: number,
	xpBreakdown: { { label: string, amount: number } },
	totalXp: number,
	challenges: { { id: string, label: string, progress: number, target: number, xpReward: number } },
})
	placement:set(data.placement)
	xpBreakdown:set(data.xpBreakdown)
	challenges:set(data.challenges)
	displayXp:set(data.previousExp)
	gui.Enabled = true
	task.delay(0.3, function()
		displayXp:set(data.previousExp + data.totalXp)
	end)
end

return RoundSummaryGui
