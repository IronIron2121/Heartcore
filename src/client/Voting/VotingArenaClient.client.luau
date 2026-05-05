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
local VotingStages 	   = workspace:WaitForChild("VotingStages")

-- Modules
local Constants = require(ReplicatedStorage.Constants)
local UI_CONSTANTS  = require(Utility:WaitForChild("UI_CONSTANTS"))
local ArenaTimerHud = require(FusionComponents:WaitForChild("ArenaTimerHud"))

-- Remotes / Values
--local ArenaRoundStartedRE    = Remotes:WaitForChild("ArenaRoundStartedRE")
local ArenaActivateRE        = Remotes:WaitForChild("ArenaActivateRE")
local ArenaVotingCompleteRE  = Remotes:WaitForChild("ArenaVotingCompleteRE")
local CurrentStateName       = Values:WaitForChild("CurrentStateName") :: StringValue
local ArenaTimerSeconds 	= Values:WaitForChild("ArenaTimerSeconds")
local SplitVoteIconsRE 		= Remotes:WaitForChild("SplitVoteIconsRE")
local RestoreVoteIconsRE	= Remotes:WaitForChild("RestoreVoteIconsRE")

-- Instances
local stage = VotingStages.VotingStage1

local LocalPlayer = Players.LocalPlayer
local hoverHighlight = Instance.new("Highlight")
hoverHighlight.Name = "VoteHighlight"
hoverHighlight.Parent = LocalPlayer
hoverHighlight.Adornee = nil
hoverHighlight.FillColor = UI_CONSTANTS.TASTEMAKER_GREEN


-- ─── Camera ─────────────────────────────────────────────────────────────────
local savedCameraType:   Enum.CameraType = Enum.CameraType.Custom
local savedCameraCFrame: CFrame          = CFrame.identity

local function computeJudgeCFrame(): CFrame
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

local function stopCountdown()
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	ArenaTimerHud.setTimer(0)
end

-- ─── Activate / deactivate ──────────────────────────────────────────────────
local function activate()
	local camera = workspace.CurrentCamera
	savedCameraType  = camera.CameraType
	savedCameraCFrame = camera.CFrame

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame     = computeJudgeCFrame()
end

local function deactivate()
	stopCountdown()

	local camera = workspace.CurrentCamera
	camera.CameraType = savedCameraType
	-- Only restore CFrame when switching back to Scriptable; Custom manages itself
	if savedCameraType == Enum.CameraType.Scriptable then
		camera.CFrame = savedCameraCFrame
	end
end

-- ─── Connections ────────────────────────────────────────────────────────────

SplitVoteIconsRE.OnClientEvent:Connect(function(currentVotes: {[number] : string})  
	local leftVotes = {}
	local rightVotes = {}

	for userId, voteSide in currentVotes do
		if voteSide == Constants.VOTE_SIDES.LEFT then
			table.insert(leftVotes, userId)
		elseif voteSide == Constants.VOTE_SIDES.RIGHT then
			table.insert(rightVotes, userId)
		else
			warn("Unhandled vote at SplitVoteIcons", userId, voteSide)
		end
	end

	for idex, userId in ipairs(leftVotes) do
		--[[
		local thumbnail = voteThumbnails.get(userId)
		if not thumbnail then return end

		thumbnail.shiftLeft()		
		]]
	end

	for index, userId in ipairs(rightVotes) do
		--[[
		local thumbnail = voteThumbnails.get(userId)
		if not thumbnail then return end

		thumbnail.shiftRight()		
		]]
	end


		--[[
		

		]]


	--[[
	local leftIndex = 0
	local rightIndex = 0
	for userId, voteSide in currentVotes do
		if voteSide == Constants.VOTE_SIDES.LEFT then
			-- Move to the left box
			local voteIcon = middleVoteBox.getIcon(userId)
			local leftSlotPosition = leftVoteBox.getSlotPosition(leftIndex)
			voteIcon.updateSpring(leftSlotPosition)
			leftIndex += 1
		elseif voteSide == Constants.VOTE_SIDES.RIGHT then
			local voteIcon = middleVoteBox.getIcon(userId)
			local rightSlotPosition = rightVoteBox.getSlotPosition(rightIndex)
			voteIcon.updateSpring(rightSlotPosition)
			rightIndex += 1
			-- Move to the right box
		end
	end
	]]
end)

RestoreVoteIconsRE.OnClientEvent:Connect(function()  
	-- Move all of the icons back to the middle
	--[[
	index = 0
	for voteIcon in rightVoteBox.getIcons() do
		voteIcon.updateSpring(middleVoteBox.getSlotPosition(index))
		index += 1
	end

	for voteIcon in rightVoteBox.getIcons() do
		voteIcon.updateSpring(middleVoteBox.getSlotPosition(index))
		index += 1
	end
	]]
end)

-- Server fires this just before teleporting — lock camera first
ArenaActivateRE.OnClientEvent:Connect(function()
	activate()
end)

-- Server fires this when all outfits have been voted on
ArenaVotingCompleteRE.OnClientEvent:Connect(function()
	stopCountdown()
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

local function connectClickDetector(clickDetector: ClickDetector)
	local target = clickDetector.Parent

	clickDetector.MouseHoverEnter:Connect(function()
		hoverHighlight.Adornee = target
	end)

	clickDetector.MouseHoverLeave:Connect(function()
		hoverHighlight.Adornee = nil
	end)
end

CollectionService:GetInstanceAddedSignal("VoteHandler"):Connect(connectClickDetector)

-- When detectors are destroyed (vote cast), clear any active highlight immediately
CollectionService:GetInstanceRemovedSignal("VoteHandler"):Connect(function()
	hoverHighlight.Adornee = nil
end)

ArenaTimerSeconds.Changed:Connect(function(newValue: number)  
	ArenaTimerHud.setTimer(newValue)
end)