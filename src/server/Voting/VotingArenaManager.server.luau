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

-- Values
local CurrentStateName = Values:WaitForChild("CurrentStateName") :: StringValue

-- Constants
local VOTE_TIMER       = 120    -- seconds per matchup before auto-vote (champion wins)
local HRP_STAND_OFFSET = 3.2   -- studs above platform surface to HumanoidRootPart
local QUEUE_SHIFT_TIME = 0.4   -- seconds for queue mannequins to slide forward
local VICTORY_ANIM_ID  = "rbxassetid://507770239"  -- Roblox "Wave" emote
local OOF_SOUND_ID     = "rbxassetid://79348298352567"  -- classic Roblox oof

-- ─── Stage types ────────────────────────────────────────────────────────────

type JudgePlatforms = Folder & {
	JudgePlatform:   BasePart,
	LeftChallenger:  BasePart,
	RightChallenger: BasePart,
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
	stageIndex:        number,
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
local stageAssignments: { [number]: number }  = {}  -- UserId → stageIndex 1-8

-- ─── ArenaRoundStartedRE ────────────────────────────────────────────────────
-- Created here so the client can WaitForChild it.

local ArenaRoundStartedRE = Instance.new("RemoteEvent")
ArenaRoundStartedRE.Name = "ArenaRoundStartedRE"
ArenaRoundStartedRE.Parent = Remotes

-- Fired before teleportation so the client can lock the camera first
local ArenaActivateRE = Instance.new("RemoteEvent")
ArenaActivateRE.Name = "ArenaActivateRE"
ArenaActivateRE.Parent = Remotes

-- ─── Forward declarations (cyclic call graph) ───────────────────────────────

local onVote: (player: Player, winnerSide: "left" | "right") -> ()
local attachVoteHandlers: (player: Player) -> ()
local advanceQueue: (player: Player) -> ()

-- ─── Helpers ────────────────────────────────────────────────────────────────

local function getStage(index: number): VotingStageFolder
	return VotingStages:FindFirstChild("VotingStage" .. index) :: VotingStageFolder
end

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
	if old then old:Destroy() end
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

local function cancelTimer(player: Player)
	local state = playerStates[player.UserId]
	if state then
		state.timerToken += 1
	end
end

local function startMatchupTimer(player: Player)
	local state = playerStates[player.UserId]
	if not state then return end
	cancelTimer(player)
	-- Tell client to reset visual countdown display
	ArenaRoundStartedRE:FireClient(player, VOTE_TIMER)
	-- Capture the token; if it changes before the delay fires, the vote is stale
	local token = state.timerToken
	task.delay(VOTE_TIMER, function()
		local currentState = playerStates[player.UserId]
		if currentState and currentState.timerToken == token then
			onVote(player, "left")
		end
	end)
end

-- ─── Cleanup ────────────────────────────────────────────────────────────────

local function cleanupPlayer(player: Player)
	local state = playerStates[player.UserId]
	if not state then return end
	cancelTimer(player)
	if state.championModel  then state.championModel:Destroy()  end
	if state.challengerModel then state.challengerModel:Destroy() end
	for _, m in ipairs(state.queueModels) do
		if m then m:Destroy() end
	end
	player:SetAttribute("VotingStageIndex", nil)
	playerStates[player.UserId] = nil
end

local function cleanupAll()
	for userId in playerStates do
		local player = Players:GetPlayerByUserId(userId)
		if player then cleanupPlayer(player) end
	end
	playerStates = {}
	stageAssignments = {}
end

-- ─── Core voting loop ───────────────────────────────────────────────────────

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
		GameStateManager.markFinishedVoting(player)
		return
	end

	-- Slide new challenger into the right slot
	tweenMannequinTo(newChallenger, rightP, judgeP)
	state.challengerModel    = newChallenger
	state.challengerOutfitId = newChallengerId
	-- Mark as seen now that it is in a challenger slot (not on queue entry)
	GameOutfitManager.showOutfitToPlayer(player.UserId, newChallengerId)

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
attachVoteHandlers = function(player: Player)
	local state = playerStates[player.UserId]
	if not state then return end

	local champCD = state.championModel  and makeDetector(state.championModel)
	local challCD = state.challengerModel and makeDetector(state.challengerModel)

	local function destroyBoth()
		if champCD and champCD.Parent then champCD:Destroy() end
		if challCD and challCD.Parent then challCD:Destroy() end
	end

	if champCD then
		champCD.MouseClick:Connect(function(clicker: Player)
			if clicker == player then
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
onVote = function(player: Player, winnerSide: "left" | "right")
	local state = playerStates[player.UserId]
	if not state or state.voteLocked then return end
	state.voteLocked = true
	cancelTimer(player)

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

	-- Record the vote server-side
	GameOutfitManager.addVote(player, winnerId)
	DataManager.AddExp(player, ExpConfig.Rewards.VOTE_CAST)
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

local function initPlayerSession(player: Player)

	print("Initialising player session")

	-- Get the index of the player's assigned stage
	local stageIndex = stageAssignments[player.UserId]
	if not stageIndex then 
		warn("no stage index for player" .. player.Name)
		return 
	end

	-- Get the stage folder; the judge platform; the left and right platforms, and the queue playforms
	local stage  = getStage(stageIndex)
	local judgeP = stage.JudgePlatforms.JudgePlatform
	local leftP  = stage.JudgePlatforms.LeftChallenger
	local rightP = stage.JudgePlatforms.RightChallenger
	local queueF = stage.QueuePlatforms

	-- Tell the client to lock its camera before we move the character
	ArenaActivateRE:FireClient(player, stageIndex)
	task.wait(0.3)

	-- Teleport player precisely to their judge platform (no scatter — camera is already locked)
	local char = player.Character or player.CharacterAdded:Wait()
	teleportPlayer(player, judgeP)

	-- Anchor them in place
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then hrp.Anchored = true end

	-- Collect all outfits this player is eligible to vote on (everyone else's)
	local ordered: { GameOutfitManager.Outfit } = {}
	for _, outfit in GameOutfitManager.getOutfits() do
		if outfit.userId ~= player.UserId then
			table.insert(ordered, outfit)
		end
	end

	if #ordered == 0 then
		print("No  outfits to use!")
		GameStateManager.markFinishedVoting(player)
		return
	else
		print("Got outfits", ordered)
	end

	local state: ArenaState = {
		stageIndex        = stageIndex,
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

	playerStates[player.UserId] = state

	-- Place champion in the left challenger slot and mark as seen
	local champOutfit = ordered[1]
	state.championModel    = createMannequin(champOutfit, leftP, judgeP)
	state.championOutfitId = champOutfit.outfitId
	GameOutfitManager.showOutfitToPlayer(player.UserId, champOutfit.outfitId)

	-- Place first challenger in the right slot and mark as seen
	if ordered[2] then
		local challOutfit = ordered[2]
		state.challengerModel    = createMannequin(challOutfit, rightP, judgeP)
		state.challengerOutfitId = challOutfit.outfitId
		GameOutfitManager.showOutfitToPlayer(player.UserId, challOutfit.outfitId) 
	end

	-- Populate the queue with outfits 3..7 (up to 5 slots)
	for slotNum = 1, 5 do
		local outfitIndex = slotNum + 2   -- ordered[3] → slot 1, ordered[7] → slot 5
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

-- ─── Voting start hook (registered with GameStateManager) ───────────────────

GameStateManager.onVotingStart = function()
	-- Assign each player to a stage (1-indexed, one-to-one)
	stageAssignments = {}
	local players = Players:GetPlayers()

	-- Set stage assignments for every player (i.e. which stage they are going to be teleported to) and set an attribute in their player to relate to it
	-- Each player ID is the key relating to a value representing their stage index
	for i, player in ipairs(players) do
		stageAssignments[player.UserId] = i
		player:SetAttribute("VotingStageIndex", i)
	end
	-- Initialise each player's arena session in parallel
	for _, player in ipairs(players) do
		task.spawn(initPlayerSession, player)
	end
end

-- ─── Lifecycle connections ───────────────────────────────────────────────────

-- Clean up all arenas when the game leaves the Voting state
CurrentStateName.Changed:Connect(function(newState: string)
	if newState ~= "Voting" then
		cleanupAll()
	end
end)

-- Clean up a player's arena if they leave mid-voting
Players.PlayerRemoving:Connect(function(player: Player)
	if playerStates[player.UserId] then
		cleanupPlayer(player)
	end
end)
