--!strict
-- VotingArenaManager.server.luau
-- Manages the 3D Colosseum voting arena. Assigns players to pre-built VotingStage
-- instances, spawns outfit mannequins server-side, handles ClickDetector votes,
-- and drives the winner-stays / queue-shift loop.

-- Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService      = game:GetService("TweenService")

-- Folders
local GameLoop     = ReplicatedStorage:WaitForChild("GameLoop")
local Libraries    = ReplicatedStorage:WaitForChild("Libraries")
local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local UtilityFolder = ReplicatedStorage:WaitForChild("Utility")
local Values       = ReplicatedStorage:WaitForChild("Values")
local VotingStages = workspace:WaitForChild("VotingStages")

-- Modules
local DataManager              = require(ServerScriptService.Data.DataManager)
local ExpConfig                = require(Libraries.ExpConfig)
local GameOutfitManager        = require(GameLoop:WaitForChild("GameOutfitManager"))
local GameStateManager         = require(GameLoop:WaitForChild("GameStateManager"))
local ServerCustomisationService = require(UtilityFolder.ServerCustomisationService)
local teleportPlayer           = require(UtilityFolder.teleportPlayer)

-- Instances
local VotingStage = VotingStages:WaitForChild("VotingStage1")
local stage       = VotingStage
local judgeP      = stage.JudgePlatforms.JudgePlatform
local teleportP   = stage.JudgePlatforms.TeleportPlatform
local leftP       = stage.JudgePlatforms.LeftChallenger
local rightP      = stage.JudgePlatforms.RightChallenger
local queueF      = stage.QueuePlatforms

-- Values
local CurrentStateName = Values:WaitForChild("CurrentStateName") :: StringValue

-- Constants
local VOTE_TIMER       = 10    -- seconds per matchup before auto-vote (champion wins)
local HRP_STAND_OFFSET = 3.2   -- studs above platform surface to HumanoidRootPart
local QUEUE_SHIFT_TIME = 0.4   -- seconds for queue mannequins to slide forward
local VICTORY_ANIM_ID  = "rbxassetid://507770239"  -- Roblox "Wave" emote
local OOF_SOUND_ID     = "rbxassetid://79348298352567"  -- classic Roblox oof

-- Lists
local state: ArenaState?

-- ─── Stage types ────────────────────────────────────────────────────────────

type JudgePlatforms = Folder & {
	JudgePlatform:    BasePart,
	TeleportPlatform: BasePart,
	LeftChallenger:   BasePart,
	RightChallenger:  BasePart,
}

type QueuePlatforms = Folder & {
	["1"]: BasePart,
	["2"]: BasePart,
	["3"]: BasePart,
	["4"]: BasePart,
	["5"]: BasePart,
}

type VotingStageFolder = Folder & {
	JudgePlatforms: JudgePlatforms,
	QueuePlatforms: QueuePlatforms,
}

-- ─── State ──────────────────────────────────────────────────────────────────

type ArenaState = {
	stage:             VotingStageFolder,
	orderedOutfits:    { GameOutfitManager.Outfit },
	nextQueueIndex:    number,       -- next orderedOutfits index to backfill slot 5
	championModel:     Model?,
	challengerModel:   Model?,
	championOutfitId:  string?,
	challengerOutfitId: string?,
	queueModels:       { Model? },   -- [1]=slot1 (next up) .. [5]=slot5 (furthest)
	queueOutfitIds:    { string? },  -- parallel to queueModels
	voteLocked:        boolean,
	timerToken:        number,       -- incremented to invalidate any pending auto-vote
}

local playerStates: { [number]: ArenaState } = {}   -- keyed by UserId

-- ─── Forward declarations (cyclic call graph) ───────────────────────────────
local onPlayerVoted: (player: Player, votedFor: "left" | "right", isAutoVote: boolean?) -> ()
local onVotingEnded: () -> ()
local attachVoteHandlers: (player: Player) -> ()
local advanceQueue: (player: Player) -> ()

-- ─── ArenaRoundStartedRE ────────────────────────────────────────────────────
-- Created here so the client can WaitForChild it.

local ArenaRoundStartedRE = Instance.new("RemoteEvent")
ArenaRoundStartedRE.Name = "ArenaRoundStartedRE"
ArenaRoundStartedRE.Parent = Remotes

-- Fired before teleportation so the client can lock the camera first
local ArenaActivateRE = Instance.new("RemoteEvent")
ArenaActivateRE.Name = "ArenaActivateRE"
ArenaActivateRE.Parent = Remotes

-- Fired when this player has voted on all outfits (queue exhausted)
local ArenaVotingCompleteRE = Instance.new("RemoteEvent")
ArenaVotingCompleteRE.Name = "ArenaVotingCompleteRE"
ArenaVotingCompleteRE.Parent = Remotes

-- ─── Helpers ────────────────────────────────────────────────────────────────
-- Compute the world CFrame for standing on top of a BasePart, facing facingPart.
local function standCFrameOn(targetPart: BasePart, facingPart: BasePart): CFrame
	local standPos = targetPart.Position + Vector3.new(0, targetPart.Size.Y / 2 + HRP_STAND_OFFSET, 0)
	-- Look horizontally toward facingPart (keep Y level to avoid tilting)
	local lookTarget = Vector3.new(facingPart.Position.X, standPos.Y, facingPart.Position.Z)
	return CFrame.lookAt(standPos, lookTarget)
end

local function createMannequin(outfit: GameOutfitManager.Outfit, targetPart: BasePart, judgeP: BasePart): Model?
	warn("Creating mannequin") 

	local success, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(
			outfit.humanoidDescription,
			Enum.HumanoidRigType.R15
		)
	end)

	if not success or not model then
		warn("VotingArenaManager: failed to create mannequin for outfit", outfit.outfitId)
		return nil
	end
 
	-- Remove any auto-running scripts
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") then d:Destroy() end
	end

	model:PivotTo(standCFrameOn(targetPart, judgeP))
	model:FindFirstChild("HumanoidRootPart").Anchored = true
	model.Parent = workspace

	return model
end

-- Starts a TweenService tween on the mannequin's PrimaryPart to slide it to a new
-- platform position while keeping it facing the judge.
local function tweenMannequinTo(model: Model, targetPart: BasePart, judgeP: BasePart)
	if not model.PrimaryPart then return end
	TweenService:Create(
		model.PrimaryPart,
		TweenInfo.new(QUEUE_SHIFT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = standCFrameOn(targetPart, judgeP) }
	):Play()
end

local function makeDetector(model: Model): ClickDetector
	local old = model:FindFirstChild("voteHandler")
	if old then 
		old:Destroy() 
	end

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 500
	cd.Name = "voteHandler"
	cd:AddTag("VoteHandler")
	cd.Parent = model

	return cd
end

-- ─── Animations ─────────────────────────────────────────────────────────────

-- Plays the distorted oof sound, freezes the humanoid, then fades the model out
-- and destroys it. Yields for the full animation (~2.3s).
local function playDeathAnimation(model: Model)
	-- Ragdoll: unanchor every part and sever all Motor6D joints so limbs scatter
	for _, desc in model:GetDescendants() do
		if desc:IsA("Motor6D") then
			desc.Enabled = false
		elseif desc:IsA("BasePart") then
			desc.Anchored = false
		end
	end

	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		local sound = Instance.new("Sound")
		sound.SoundId = OOF_SOUND_ID
		sound.Volume = 0.1
		sound.Parent = hrp
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 3)
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = 0 end
	task.wait(1.5)
	-- Fade out all visible parts
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") or p:IsA("Decal") then
			TweenService:Create(p, TweenInfo.new(0.8), { Transparency = 1 }):Play()
		end
	end
	task.wait(0.8)
	model:Destroy()
end

-- Plays the wave emote on the mannequin's Animator (non-blocking).
-- Pass looped = true to keep the animation playing indefinitely (e.g. end-of-round celebration).
local function playVictoryAnimation(model: Model, looped: boolean?)
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = VICTORY_ANIM_ID
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok or not track then return end
	track.Looped = looped == true
	track:Play()
	if not looped then
		task.delay(track.Length or 2, function()
			if track.IsPlaying then track:Stop() end
		end)
	end
end

local function playAnimationOnce(model: Model, animationId: number)
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then return end
local emote = ServerCustomisationService.LoadEmote(animationId)
	if not emote then
		warn("VotingArenaManager: failed to load emote", animationId)
		return
	end
	local ok, track = pcall(function() return animator:LoadAnimation(emote) end)
	if not ok or not track then
		warn("Failed to load animation track")
		return
	end
	track.Looped = false
	track:Play()
end

-- ─── Timer ──────────────────────────────────────────────────────────────────

local function cancelTimer()
	if state then
		state.timerToken += 1
	end
end

local function startMatchupTimer()
	if not state then 
		warn("No state at start matchup!")
		return 
	end
	
	cancelTimer()
	-- Tell client to reset visual countdown display
	ArenaRoundStartedRE:FireAllClients(VOTE_TIMER)
	-- Capture the token; if it changes before the delay fires, the vote is stale
	local token = state.timerToken
	task.delay(VOTE_TIMER, function()
		local currentState = playerStates[player.UserId]
		if currentState and currentState.timerToken == token then
			onVote(player, "left", true)   -- auto-vote: champion wins, no score recorded
		end
	end)
end

-- ─── Cleanup ────────────────────────────────────────────────────────────────
local function cleanupPlayer()

end

local function cleanupArena()
	if not state then 
		warn("No state at clean-up arena")
		return 
	end

	cancelTimer()

	if state.championModel  then state.championModel:Destroy()  end
	if state.challengerModel then state.challengerModel:Destroy() end

	for _, m in ipairs(state.queueModels) do
		if m then 
			m:Destroy() 
		end
	end

	-- Unanchor the player now that they're being returned to the intermission zone
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then hrp.Anchored = false end
		player:SetAttribute("VotingStageIndex", nil)
		playerStates[player.UserId] = nil
	end
	state = nil
end

-- ─── Core voting loop ───────────────────────────────────────────────────────

onPlayerVoted = function(player: Player, votedFor: string)

end

-- Called after a vote resolves. Slides the next queue mannequin to RightChallenger,
-- shifts the rest of the queue forward, and backfills slot 5 if more outfits exist.
onVotingEnded = function()
	if not state or state.voteLocked then return end
	state.voteLocked = true
	cancelTimer()

	-- Destroy click detectors on both models (handles the auto-vote path where
	-- destroyBoth() inside attachVoteHandlers was never called)
	local function destroyDetector(model: Model?)
		if not model then return end
		local cd = model:FindFirstChild("voteHandler")
		if cd then 
			cd:Destroy() 
		end
	end
	destroyDetector(state.championModel)
	destroyDetector(state.challengerModel)

	local winnerModel:   Model?
	local winnerId:      string?
	local loserModel:    Model?

	-- Count the votes
	-- So first we need to tally them up

	if winnerSide == "left" then
		winnerModel = state.championModel;   winnerId = state.championOutfitId
		loserModel  = state.challengerModel
	else
		winnerModel = state.challengerModel; winnerId = state.challengerOutfitId
		loserModel  = state.championModel
	end

	if not winnerModel or not winnerId or not loserModel then return end

	-- Record the vote server-side (skipped for auto-votes on timeout)
	if not isAutoVote then
		GameOutfitManager.addVote(player, winnerId)
		DataManager.AddExp(player, ExpConfig.Rewards.VOTE_CAST)
	end
	playAnimationOnce(winnerModel, 3994127840)

	task.spawn(function()
		-- Victory plays on the winner (non-blocking); death on loser (blocking ~2.3s)
		playVictoryAnimation(winnerModel :: Model)
		playDeathAnimation(loserModel :: Model)   -- destroys loserModel at the end

		if winnerSide == "right" then
			-- Winner was on the right — slide them to the left (champion) slot
			local leftP = state.stage.JudgePlatforms.LeftChallenger
			local judgeP = state.stage.JudgePlatforms.JudgePlatform
			tweenMannequinTo(winnerModel :: Model, leftP, judgeP)
			state.championModel    = winnerModel
			state.championOutfitId = winnerId
		end
		state.challengerModel    = nil
		state.challengerOutfitId = nil

		advanceQueue(player)
	end)
end

-- ─── Session initialisation ─────────────────────────────────────────────────

local function initialisePlayerVoting(player: Player)
	-- Lock player movement
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then hrp.Anchored = true end
	-- Tell the client to lock its camera before we move the character
	ArenaActivateRE:FireClient(player)
	task.wait(0.3)
	-- Teleport the rig to TeleportPlatform; camera stays on JudgePlatform POV
	teleportPlayer(player, teleportP)
end

local function initVotingSession()
	for _, player in Players:GetPlayers() do
		initialisePlayerVoting(player)
	end

	-- Collect all outfits this player is eligible to vote on (everyone else's)
	local ordered: { GameOutfitManager.Outfit } = {}
	for _, outfit in GameOutfitManager.getOutfits() do
		table.insert(ordered, outfit)
	end

	if #ordered == 0 then
		warn("No outfits to use!")
		return
	else
		print("Got outfits", ordered)
	end

	state = {
		stage             = stage,
		orderedOutfits    = ordered,
		nextQueueIndex    = 8,     -- indices 1-7 placed at init; 8 onwards are backfill
		championModel     = nil,
		challengerModel   = nil,
		championOutfitId  = nil,
		challengerOutfitId = nil,
		queueModels       = {},
		queueOutfitIds    = {},
		voteLocked        = false,
		timerToken        = 0,
	}

	-- Place champion in the left challenger slot and mark as seen
	local champOutfit = ordered[1]
	state.championModel    = createMannequin(champOutfit, leftP, judgeP)
	state.championOutfitId = champOutfit.outfitId
	GameOutfitManager.showOutfitToPlayers(champOutfit.outfitId)

	-- Place first challenger in the right slot and mark as seen
	if ordered[2] then
		local challOutfit = ordered[2]
		state.challengerModel    = createMannequin(challOutfit, rightP, judgeP)
		state.challengerOutfitId = challOutfit.outfitId
		GameOutfitManager.showOutfitToPlayers(challOutfit.outfitId) 
	end

	-- Populate the queue with outfits 3..7 (up to 5 slots)
	for slotNum = 1, 5 do
		local outfitIndex = slotNum + 2 -- ordered[3] → slot 1, ordered[7] → slot 5
		local outfit = ordered[outfitIndex]
		if not outfit then break end
		local slotPart = queueF:FindFirstChild(tostring(slotNum)) :: BasePart?
		if slotPart then
			state.queueModels[slotNum]    = createMannequin(outfit, slotPart, judgeP)
			state.queueOutfitIds[slotNum] = outfit.outfitId
		end
	end

	-- Start the first matchup if both challenger slots are filled
	if state.challengerModel then
		attachVoteHandlers(player)
		startMatchupTimer(player)
	else
		-- Only one outfit existed — player wins by default
		playVictoryAnimation(state.championModel :: Model)
		warn("Only one outfit; marking finished", state, state.challengerModel)
		task.wait(2)
		cleanupPlayer(player)
		GameStateManager.markFinishedVoting(player)
	end
end

--

-- Called after a vote resolves. Slides the next queue mannequin to RightChallenger,
-- shifts the rest of the queue forward, and backfills slot 5 if more outfits exist.
advanceQueue = function(player: Player)
	warn("advancing queue")
	local state = playerStates[player.UserId]
	if not state then return end

	local stage  = state.stage
	local judgeP = stage.JudgePlatforms.JudgePlatform
	local rightP = stage.JudgePlatforms.RightChallenger
	local queueF = stage.QueuePlatforms

	local newChallenger   = state.queueModels[1]
	local newChallengerId = state.queueOutfitIds[1]

	if not newChallenger or not newChallengerId then
		-- Queue empty — champion celebrates on the podium until the round ends
		playVictoryAnimation(state.championModel :: Model, true)
		ArenaVotingCompleteRE:FireClient(player)
		GameStateManager.markFinishedVoting(player)
		return
	end

	-- Slide new challenger into the right slot
	tweenMannequinTo(newChallenger, rightP, judgeP)
	state.challengerModel    = newChallenger
	state.challengerOutfitId = newChallengerId
	-- Mark as seen now that it is in a challenger slot (not on queue entry)
	GameOutfitManager.showOutfitToPlayers(newChallengerId)

	-- Shift remaining queue models forward one slot simultaneously
	for i = 1, 4 do
		state.queueModels[i]    = state.queueModels[i + 1]
		state.queueOutfitIds[i] = state.queueOutfitIds[i + 1]
		if state.queueModels[i] then
			local slotPart = queueF:FindFirstChild(tostring(i))
			if slotPart then
				tweenMannequinTo(state.queueModels[i] :: Model, slotPart, judgeP)
			end
		end
	end

	state.queueModels[5]    = nil
	state.queueOutfitIds[5] = nil

	-- Backfill slot 5 if there are more outfits beyond what was pre-loaded
	local nextOutfit = state.orderedOutfits[state.nextQueueIndex]
	if nextOutfit then
		local slotPart = queueF:FindFirstChild("5")
		if slotPart then
			state.queueModels[5]    = createMannequin(nextOutfit, slotPart, judgeP)
			state.queueOutfitIds[5] = nextOutfit.outfitId
		end
		state.nextQueueIndex += 1
	end

	-- Reattach click handlers for the new matchup and start the per-vote timer
	state.voteLocked = false
	attachVoteHandlers(player)
	startMatchupTimer(player)
end

-- Wires ClickDetectors on the current champion and challenger mannequins.
-- Both detectors are destroyed together the moment either is clicked.
attachVoteHandlers = function()
	if not state then return end

	local champCD = state.championModel  and makeDetector(state.championModel)
	local challCD = state.challengerModel and makeDetector(state.challengerModel)

	local function destroyBoth()
		if champCD and champCD.Parent then champCD:Destroy() end
		if challCD and challCD.Parent then challCD:Destroy() end
	end

	if champCD then
		champCD.MouseClick:Connect(function(clicker: Player)
			if clicker then
				destroyBoth()
				onVote(player, "left")
			end
		end)
	end

	if challCD then
		challCD.MouseClick:Connect(function(clicker: Player)
			if clicker == player then
				destroyBoth()
				onVote(player, "right")
			end
		end)
	end
end

-- Handles a vote: records it, runs animations, slides the winner if needed,
-- then calls advanceQueue to bring in the next challenger.
onVote = function(player: Player, winnerSide: "left" | "right", isAutoVote: boolean?)
	local state = playerStates[player.UserId]
	if not state or state.voteLocked then return end
	state.voteLocked = true
	cancelTimer(player)

	-- Destroy click detectors on both models (handles the auto-vote path where
	-- destroyBoth() inside attachVoteHandlers was never called)
	local function destroyDetector(model: Model?)
		if not model then return end
		local cd = model:FindFirstChild("voteHandler")
		if cd then cd:Destroy() end
	end
	destroyDetector(state.championModel)
	destroyDetector(state.challengerModel)

	local winnerModel:   Model?
	local winnerId:      string?
	local loserModel:    Model?

	if winnerSide == "left" then
		winnerModel = state.championModel;   winnerId = state.championOutfitId
		loserModel  = state.challengerModel
	else
		winnerModel = state.challengerModel; winnerId = state.challengerOutfitId
		loserModel  = state.championModel
	end

	if not winnerModel or not winnerId or not loserModel then return end

	-- Record the vote server-side (skipped for auto-votes on timeout)
	if not isAutoVote then
		GameOutfitManager.addVote(player, winnerId)
		DataManager.AddExp(player, ExpConfig.Rewards.VOTE_CAST)
	end
	playAnimationOnce(winnerModel, 3994127840)

	task.spawn(function()
		-- Victory plays on the winner (non-blocking); death on loser (blocking ~2.3s)
		playVictoryAnimation(winnerModel :: Model)
		playDeathAnimation(loserModel :: Model)   -- destroys loserModel at the end

		if winnerSide == "right" then
			-- Winner was on the right — slide them to the left (champion) slot
			local leftP = state.stage.JudgePlatforms.LeftChallenger
			local judgeP = state.stage.JudgePlatforms.JudgePlatform
			tweenMannequinTo(winnerModel :: Model, leftP, judgeP)
			state.championModel    = winnerModel
			state.championOutfitId = winnerId
		end
		state.challengerModel    = nil
		state.challengerOutfitId = nil

		advanceQueue(player)
	end)
end

-- ─── Voting start hook (registered with GameStateManager) ───────────────────

GameStateManager.onVotingStart = function()
	initVotingSession()
end

-- ─── Lifecycle connections ───────────────────────────────────────────────────

-- Clean up all arenas when the game leaves the Voting state
CurrentStateName.Changed:Connect(function(newState: string)
	if newState ~= "Voting" then
		cleanupArena()
	end
end)

--[[
-- Clean up a player's arena if they leave mid-voting
Players.PlayerRemoving:Connect(function(player: Player)
	if playerStates[player.UserId] then
		cleanupPlayer(player)
	end
end)
]]