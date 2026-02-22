--!strict
-- VotingArenaClient.client.luau
-- Handles the client-side experience for the 3D Colosseum voting arena:
--   • Locks the camera to a judge's-POV CFrame above the assigned stage
--   • Shows a per-vote countdown timer UI

-- Services
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local Utility   = ReplicatedStorage:WaitForChild("Utility")
local Values    = ReplicatedStorage:WaitForChild("Values")

-- Modules
local Fusion        = require(Utility:WaitForChild("Fusion"))
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))

local scope    = Fusion:scoped()
local Children = Fusion.Children

-- Remotes / Values
local ArenaRoundStartedRE = Remotes:WaitForChild("ArenaRoundStartedRE")
local ArenaActivateRE     = Remotes:WaitForChild("ArenaActivateRE")
local CurrentStateName    = Values:WaitForChild("CurrentStateName") :: StringValue

-- Instances


local LocalPlayer = Players.LocalPlayer
local hoverHighlight = Instance.new("Highlight")
hoverHighlight.Name = "VoteHighlight"
hoverHighlight.Parent = LocalPlayer
hoverHighlight.Adornee = nil
hoverHighlight.FillColor = UI_CONSTANTS.TASTEMAKER_GREEN

-- ─── Reactive state ─────────────────────────────────────────────────────────

local isArenaActive = scope:Value(false)
local timerCount    = scope:Value(0)

local timerColor = scope:Computed(function(use)
	return use(timerCount) <= 3
		and Color3.fromRGB(255, 80, 80)
		or  Color3.fromRGB(255, 255, 255)
end)

local timerText = scope:Computed(function(use)
	return tostring(use(timerCount))
end)

-- ─── Timer GUI (built once, toggled via Enabled) ────────────────────────────

scope:New "ScreenGui" {
	Name             = "ArenaTimerGui",
	IgnoreGuiInset   = true,
	DisplayOrder     = 20,   -- above standard HUD elements
	ResetOnSpawn     = false,
	Enabled          = isArenaActive,
	Parent           = LocalPlayer:WaitForChild("PlayerGui"),

	[Children] = {
		scope:New "Frame" {
			Name                 = "TimerFrame",
			Size                 = UDim2.fromScale(0.08, 0.1),
			Position             = UDim2.fromScale(0.5, 0.04),
			AnchorPoint          = Vector2.new(0.5, 0),
			BackgroundColor3     = Color3.fromRGB(20, 20, 20),
			BackgroundTransparency = 0.35,

			[Children] = {
				scope:New "UICorner" {
					CornerRadius = UDim.new(0.25, 0),
				},
				scope:New "TextLabel" {
					Size                 = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text                 = timerText,
					TextScaled           = true,
					TextColor3           = timerColor,
					FontFace             = Font.new(UI_CONSTANTS.DEFAULT_FONT, Enum.FontWeight.Bold),
				},
			},
		},
	},
}

-- ─── Camera ─────────────────────────────────────────────────────────────────

local savedCameraType:   Enum.CameraType = Enum.CameraType.Custom
local savedCameraCFrame: CFrame          = CFrame.identity

local function computeJudgeCFrame(stageIndex: number): CFrame
	local stage  = workspace:WaitForChild("VotingStages"):FindFirstChild("VotingStage" .. stageIndex)
	if not stage then return CFrame.identity end
	local judgeP = (stage :: Folder):FindFirstChild("JudgePlatforms") :: Folder?
	if not judgeP then return CFrame.identity end
	local judge  = judgeP:FindFirstChild("JudgePlatform") :: BasePart?
	local leftC  = judgeP:FindFirstChild("LeftChallenger") :: BasePart?
	local rightC = judgeP:FindFirstChild("RightChallenger") :: BasePart?
	if not judge or not leftC or not rightC then return CFrame.identity end

	-- Camera sits 8 studs above JudgePlatform, looking at chest height of the challengers
	local camPos = judge.Position + Vector3.new(0, 8, 0)
	local midpoint = (leftC.Position + rightC.Position) / 2
	local lookAt = midpoint + Vector3.new(0, 5, 0)
	return CFrame.lookAt(camPos, lookAt)
end

-- ─── Countdown thread ───────────────────────────────────────────────────────

local countdownThread: thread? = nil

local function startCountdown(duration: number)
	if countdownThread then task.cancel(countdownThread) end
	timerCount:set(duration)
	countdownThread = task.spawn(function()
		local t = duration
		while t > 0 do
			task.wait(1)
			t -= 1
			timerCount:set(t)
		end
	end)
end

local function stopCountdown()
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	timerCount:set(0)
end

-- ─── Activate / deactivate ──────────────────────────────────────────────────

local function activate(stageIndex: number?)
	local idx = stageIndex or LocalPlayer:GetAttribute("VotingStageIndex")
	if not idx then return end

	local camera = workspace.CurrentCamera
	savedCameraType  = camera.CameraType
	savedCameraCFrame = camera.CFrame

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame     = computeJudgeCFrame(idx)

	isArenaActive:set(true)
end

local function deactivate()
	stopCountdown()
	isArenaActive:set(false)

	local camera = workspace.CurrentCamera
	camera.CameraType = savedCameraType
	-- Only restore CFrame when switching back to Scriptable; Custom manages itself
	if savedCameraType == Enum.CameraType.Scriptable then
		camera.CFrame = savedCameraCFrame
	end
end

-- ─── Connections ────────────────────────────────────────────────────────────

-- Server fires this just before teleporting — lock camera first
ArenaActivateRE.OnClientEvent:Connect(function(stageIndex: number)
	activate(stageIndex)
end)

-- Server fires this at the start of each matchup so the countdown resets
ArenaRoundStartedRE.OnClientEvent:Connect(function(duration: number)
	startCountdown(duration)
end)

-- Deactivate when the round ends
CurrentStateName.Changed:Connect(function(newState: string)
	if newState ~= "Voting" then
		deactivate()
	end
end)

-- Fallback: script loaded while Voting was already active (e.g. rejoin)
if CurrentStateName.Value == "Voting" then
	task.delay(0.5, activate)
end

CollectionService:GetInstanceAddedSignal("VoteHandler"):Connect(function(clickDetector: ClickDetector)
	local target = clickDetector.Parent

	clickDetector.MouseHoverEnter:Connect(function()
		hoverHighlight.Adornee = target
	end)

	clickDetector.MouseHoverLeave:Connect(function()
		hoverHighlight.Adornee = nil
	end)
end)

-- When detectors are destroyed (vote cast), clear any active highlight immediately
CollectionService:GetInstanceRemovedSignal("VoteHandler"):Connect(function()
	hoverHighlight.Adornee = nil
end)