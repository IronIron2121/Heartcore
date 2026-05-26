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
local Remotes          = ReplicatedStorage:WaitForChild("Remotes")
local Utility          = ReplicatedStorage:WaitForChild("Utility")
local Values           = ReplicatedStorage:WaitForChild("Values")
local FusionComponents = ReplicatedStorage:WaitForChild("UI"):WaitForChild("FusionComponents")

-- Modules
local VoteBarManager          = require(ReplicatedStorage.UI.FusionComponents.VoteBarManager)
local UI_CONSTANTS            = require(Utility:WaitForChild("UI_CONSTANTS"))
local ArenaTimerHud           = require(FusionComponents:WaitForChild("ArenaTimerHud"))
local ClientCameraController  = require(script.Parent.Parent.Libraries.ClientCameraController)

-- Models
local VotingZone 	   = workspace:WaitForChild("VOTING_ZONE")

-- Remotes / Values
--local ArenaRoundStartedRE    = Remotes:WaitForChild("ArenaRoundStartedRE")
local ArenaActivateRE        = Remotes:WaitForChild("ArenaActivateRE")
local ArenaVotingCompleteRE  = Remotes:WaitForChild("ArenaVotingCompleteRE")
local CurrentStateName       = Values:WaitForChild("CurrentStateName") :: StringValue
local ArenaTimerSeconds 	= Values:WaitForChild("ArenaTimerSeconds")
local VoteSubRoundCompleteRE 		= Remotes:WaitForChild("VoteSubRoundCompleteRE")
local RestoreVoteIconsRE	= Remotes:WaitForChild("RestoreVoteIconsRE")

local LocalPlayer = Players.LocalPlayer
local hoverHighlight = Instance.new("Highlight")
hoverHighlight.Name = "VoteHoverHighlight"
hoverHighlight.Parent = LocalPlayer
hoverHighlight.Adornee = nil
hoverHighlight.FillColor = UI_CONSTANTS.TASTEMAKER_GREEN

local voteHighlight = Instance.new("Highlight")
voteHighlight.Name = "voteHighlight"
voteHighlight.Parent = LocalPlayer
voteHighlight.Adornee = nil
voteHighlight.OutlineColor = UI_CONSTANTS.TASTEMAKER_PURPLE
voteHighlight.FillColor = UI_CONSTANTS.TASTEMAKER_PURPLE


-- ─── Camera ─────────────────────────────────────────────────────────────────

local function computeJudgeCFrame(): CFrame
	if not VotingZone then return CFrame.identity end
	local judgeP = (VotingZone :: Model):FindFirstChild("JudgePlatforms") :: Folder?
	if not judgeP then return CFrame.identity end
	local judge  = judgeP:FindFirstChild("JudgePlatform") :: BasePart?
	local leftC  = judgeP:FindFirstChild("LeftChallenger") :: BasePart?
	local rightC = judgeP:FindFirstChild("RightChallenger") :: BasePart?
	if not judge or not leftC or not rightC then return CFrame.identity end

	-- Camera sits 8 studs above JudgePlatform, looking at chest height of the challengers
	local camPos = judge.Position + Vector3.new(0, 10, 12)
	local midpoint = (leftC.Position + rightC.Position) / 2
	local lookAt = midpoint + Vector3.new(0, 10, 0)
	return CFrame.lookAt(camPos, lookAt)
end

-- ─── Countdown thread ───────────────────────────────────────────────────────
local countdownThread: thread? = nil

local function stopCountdown()
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	ArenaTimerHud.setTimer(0)
end

-- ─── Activate / deactivate ──────────────────────────────────────────────────
local function activate()
	ClientCameraController.activate(computeJudgeCFrame())
end

local function deactivate()
	stopCountdown()
	ArenaTimerHud.setVisible(false)
	if CurrentStateName.Value ~= "Intermission" then
		ClientCameraController.deactivate()
	end
end

-- ─── Connections ────────────────────────────────────────────────────────────

VoteSubRoundCompleteRE.OnClientEvent:Connect(
	function(currentVotes: {[number] : string})
		voteHighlight.Adornee = nil  
		VoteBarManager.splitVotes(currentVotes)
	end
)

RestoreVoteIconsRE.OnClientEvent:Connect(function()  
	VoteBarManager.restoreVotes()
end)

-- Server fires this just before teleporting — lock camera first
ArenaActivateRE.OnClientEvent:Connect(function()
	activate()
end)

-- Server fires this when all outfits have been voted on
ArenaVotingCompleteRE.OnClientEvent:Connect(function()
	stopCountdown()
	deactivate()
end)

-- Fallback: script loaded while Voting was already active (e.g. rejoin)
if CurrentStateName.Value == "Voting" then
	task.delay(0.5, activate)
end

local function connectClickDetector(clickDetector: ClickDetector)
	local target = clickDetector.Parent

	clickDetector.MouseClick:Connect(
		function(player: Player)
			voteHighlight.Adornee = clickDetector.Parent	
		end
	)

	clickDetector.MouseHoverEnter:Connect(
		function()
			hoverHighlight.Adornee = target
		end
	)

	clickDetector.MouseHoverLeave:Connect(
		function()
			hoverHighlight.Adornee = nil
		end
	)
end

CollectionService:GetInstanceAddedSignal("VoteHandler"):Connect(connectClickDetector)

-- When detectors are destroyed (vote cast), clear any active highlight immediately
CollectionService:GetInstanceRemovedSignal("VoteHandler"):Connect(function()
	hoverHighlight.Adornee = nil
end)

ArenaTimerSeconds.Changed:Connect(function(newValue: number)  
	print("Arena timer seconds changed")
	ArenaTimerHud.setTimer(newValue)
	ArenaTimerHud.setVisible(true)
end)