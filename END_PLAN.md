# Plan: 3D Colosseum Voting Arena (MVP)

## Context

Replaces the existing flat 2D tile-based voting UI with a theatrical "Colosseum" experience. Each voting player becomes a judge in their own private arena: two outfit mannequins face off in the world in front of them, the player clicks one to vote, the loser dies (distorted oof + fade), the winner stays and plays a victory animation, and the next challenger slides in from the side. This is all client-side (private per player — no shared arena, no spectating in MVP).

---

## Files to Create / Modify

| Action | File | What changes |
|--------|------|-------------|
| **Create** | `src/client/Voting/VotingArena.client.luau` | Entire arena system |
| **Modify** | `src/repstore/GameLoop/GameOutfitManager.luau` | Line 194-196: sort by votes |
| **Modify** | `src/server/Init/RemotesInit.server.luau` | Line 35: accept `excludeOutfitId` arg |
| **Modify** | `src/repstore/UI/FusionComponents/VotingFrame/init.luau` | Line 258: suppress when arena active |
| **Modify** | `src/client/GUI/GuiManager/InitialiseGuiManager.client.luau` | Line 182-183: suppress Vote button push |

---

## Architecture

- **Private arenas**: Mannequins created in a LocalScript and parented to `workspace` — only the local client sees them. Players vote simultaneously without interfering with each other.
- **Camera**: Switched to `Enum.CameraType.Scriptable` during Voting state, restored on deactivate.
- **Click detection**: `ClickDetector` (MaxActivationDistance = 100) on each mannequin's `HumanoidRootPart`. LocalScript connects `MouseClick`.
- **Suppression flag**: A `BoolValue "ArenaVotingActive"` created at runtime in `ReplicatedStorage` prevents the 2D VotingFrame modal from opening while the arena is active.
- **Remotes reused unchanged**: Same `GetNextOutfitRF`, `SubmitVoteRF`, `GetUnseenCountRF` wire protocol.

---

## Step 1 — Server: accept excludeOutfitId

**`src/server/Init/RemotesInit.server.luau`, line 35:**

```lua
-- Before:
GetNextOutfitRF.OnServerInvoke = function(player: Player)
    local currentChampionId = nil

-- After:
GetNextOutfitRF.OnServerInvoke = function(player: Player, excludeOutfitId: string?)
```

Remove the `currentChampionId = nil` line; pass `excludeOutfitId` directly to `getUnseenOutfit`. Existing 2D VotingFrame callers pass nil — no breakage.

---

## Step 2 — Server: vote ordering

**`src/repstore/GameLoop/GameOutfitManager.luau`, lines 194-196:**

```lua
-- Before:
table.sort(unseen, function(a, b)
    return a.views < b.views
end)

-- After:
table.sort(unseen, function(a, b)
    if a.votes ~= b.votes then
        return a.votes < b.votes   -- fewest votes faces first ("final boss" last)
    end
    return a.views < b.views       -- tiebreaker; effectively random at round start
end)
```

---

## Step 3 — New file: `src/client/Voting/VotingArena.client.luau`

### Constants

```lua
-- Offsets relative to VoteSpawn's local space (Vector3)
local CAMERA_POS_OFFSET  = Vector3.new(0, 4, 8)      -- behind + elevated
local CAMERA_LOOK_OFFSET = Vector3.new(0, 0, -10)     -- ahead of VoteSpawn
local LEFT_SLOT_OFFSET   = Vector3.new(-5, 0, -10)
local RIGHT_SLOT_OFFSET  = Vector3.new(5, 0, -10)
local OFFSCREEN_L_OFFSET = Vector3.new(-20, 0, -10)
local OFFSCREEN_R_OFFSET = Vector3.new(20, 0, -10)

local VOTE_TIMER      = 10
local VICTORY_ANIM_ID = "rbxassetid://507770239"  -- Roblox "Wave" emote
local OOF_SOUND_ID    = "rbxassetid://142082198"  -- classic oof
```

### Key module-level state

```lua
local isArenaActive = false
local voteLocked    = false

local championModel:     Model?  = nil
local challengerModel:   Model?  = nil
local championOutfitId:  string? = nil
local challengerOutfitId: string? = nil
local prefetchedData:    OutfitData? = nil
local voteTimerThread:   thread? = nil

-- Saved camera state
local savedCameraType:   Enum.CameraType
local savedCameraCFrame: CFrame

-- Computed slot CFrames (set once per activate())
local cameraWorldCF, leftSlotCF, rightSlotCF, offLCF, offRCF: CFrame
```

### Activation flow (`activate()`)

1. Compute world-space slot CFrames from `workspace.GeneralWorld.VoteSpawn:GetPivot()` + offsets
2. Lock camera: `camera.CameraType = Scriptable`, `camera.CFrame = cameraWorldCF`
3. Set `ArenaVotingActive.Value = true` (create the BoolValue if it doesn't exist yet)
4. Create timer ScreenGui (Fusion scope, `timerValue = scope:Value(VOTE_TIMER)`)
5. `fetchNextOutfit(nil)` → champion (left); `fetchNextOutfit(champId)` → challenger (right)
6. `createMannequin(desc, offLCF)` → slide to `leftSlotCF` (champion)
7. `createMannequin(desc, offRCF)` → slide to `rightSlotCF` (challenger) simultaneously
8. Attach ClickDetectors, start 10s timer, prefetch next in background

### `createMannequin(desc, startCF) -> Model`

```lua
local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
-- destroy BaseScript descendants (same pattern as OutfitVoteTile.lua)
model.Parent = workspace                 -- local only (LocalScript)
model:PivotTo(startCF)
local cd = Instance.new("ClickDetector")
cd.MaxActivationDistance = 100
cd.Parent = model:WaitForChild("HumanoidRootPart", 5)
CollectionService:AddTag(model, "ArenaMannequin")  -- for cleanup safety
return model
```

### Click handler attachment

Per round, destroy + recreate the champion's `ClickDetector` to avoid stale closures:

```lua
local function attachChamp(champId, challId)
    -- destroy old ClickDetector, create new one
    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 100
    cd.Parent = championModel.HumanoidRootPart
    local capChamp, capChall = championModel, challengerModel
    cd.MouseClick:Connect(function()
        onVote(capChamp, champId, capChall, challId, "left")
    end)
end
```

Challenger's `ClickDetector.MouseClick` connects once at creation:

```lua
cd.MouseClick:Connect(function()
    onVote(challengerModel, challId, championModel, champId, "right")
end)
```

### `onVote(winnerModel, winnerId, loserModel, loserId, winnerSlot)`

```lua
if voteLocked then return end
voteLocked = true
cancelTimer()
submitVote(winnerId, loserId)   -- callWithRetry, fire-and-forget

task.spawn(function()
    playVictoryAnimation(winnerModel)   -- non-blocking
    playDeathAnimation(loserModel)      -- blocking (~2.3s total)

    if winnerSlot == "right" then
        -- slide winner from right → left slot
        tweenMannequinTo(winnerModel, leftSlotCF, 0.5):Wait()
        championModel, championOutfitId = winnerModel, winnerId
    end
    challengerModel, challengerOutfitId = nil, nil

    advanceToNextChallenger()
end)
```

### `advanceToNextChallenger()`

```lua
local nextData = prefetchedData or fetchNextOutfit(championOutfitId)
prefetchedData = nil
if not nextData then finishArena(); return end

challengerModel = createMannequin(nextData.humanoidDescription, offRCF)
challengerOutfitId = nextData.outfitId
-- attach challenger click
playEntranceAnimation(challengerModel, rightSlotCF)       -- TweenService slide-in
attachChamp(championOutfitId, challengerOutfitId)          -- refresh champ click

-- pre-fetch next in background
task.delay(0.1, function()
    prefetchedData = fetchNextOutfit(challengerOutfitId)
end)

voteLocked = false
startTimer(function()   -- auto-vote champion on timeout
    onVote(championModel, championOutfitId, challengerModel, challengerOutfitId, "left")
end)
```

### Death animation

```lua
local function playDeathAnimation(model)
    -- Distorted oof
    local sound = Instance.new("Sound")
    sound.SoundId = OOF_SOUND_ID
    sound.Volume = 1.5
    sound.PlaybackSpeed = 0.55         -- pitch-shifted down = "really distorted"
    local fx = Instance.new("DistortionSoundEffect")
    fx.Level = 0.85
    fx.Parent = sound
    sound.Parent = model.HumanoidRootPart
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 3)

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end     -- freeze (no Animate script = stays in place)

    task.wait(1.5)
    for _, p in model:GetDescendants() do
        if p:IsA("BasePart") or p:IsA("Decal") then
            TweenService:Create(p, TweenInfo.new(0.8), {Transparency = 1}):Play()
        end
    end
    task.wait(0.8)
    model:Destroy()
end
```

> `CreateHumanoidModelFromDescription` doesn't include the Animate script, so no ragdoll plays automatically. The freeze + oof + fade IS the death. Full ragdoll can be added later.

### Victory animation

```lua
local function playVictoryAnimation(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    local anim = Instance.new("Animation")
    anim.AnimationId = VICTORY_ANIM_ID
    local track = hum:FindFirstChildOfClass("Animator"):LoadAnimation(anim)
    track:Play()
    task.delay(track.Length or 2, function() track:Stop() end)
end
```

### Slide animations

`TweenService:Create(model.PrimaryPart, TweenInfo.new(0.5, Quad, Out), {CFrame = target}):Play()` — tweening `PrimaryPart.CFrame` moves the whole rig.

### Timer

```lua
local function startTimer(onExpire)
    if voteTimerThread then task.cancel(voteTimerThread) end
    timerValue:set(VOTE_TIMER)
    voteTimerThread = task.spawn(function()
        local t = VOTE_TIMER
        while t > 0 do task.wait(1); t -= 1; timerValue:set(t) end
        onExpire()
    end)
end
```

### Deactivation (`deactivate()`)

- `cancelTimer()`
- Destroy `championModel`, `challengerModel`
- Destroy all `CollectionService:GetTagged("ArenaMannequin")` (leak safety)
- Destroy Fusion timer scope (`Fusion.doCleanup(timerScope)`)
- Restore camera type + CFrame
- `ArenaVotingActive.Value = false`
- Reset all state vars

### Activation trigger

```lua
local CurrentStateName = Values:WaitForChild("CurrentStateName") :: StringValue

CurrentStateName.Changed:Connect(function(state)
    if state == "Voting" then
        task.delay(1.5, activate)   -- wait for teleport to settle
    else
        deactivate()
    end
end)

if CurrentStateName.Value == "Voting" then task.delay(1.5, activate) end
```

### Requires block

```lua
local CollectionService  = game:GetService("CollectionService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")

local Remotes  = ReplicatedStorage:WaitForChild("Remotes")
local Utility  = ReplicatedStorage:WaitForChild("Utility")
local Values   = ReplicatedStorage:WaitForChild("Values")

local SerialisationService = require(Utility.SerialisationService)
local callWithRetry        = require(Utility.callWithRetry)
local Fusion               = require(Utility.Fusion)

local GetNextOutfitRF  = Remotes:WaitForChild("GetNextOutfitRF")
local GetUnseenCountRF = Remotes:WaitForChild("GetUnseenCountRF")
local SubmitVoteRF     = Remotes:WaitForChild("SubmitVoteRF")
```

---

## Step 4 — Suppress 2D VotingFrame

**`src/repstore/UI/FusionComponents/VotingFrame/init.luau`, line 258:**

```lua
local function initialiseVoting()
    local flag = ReplicatedStorage:FindFirstChild("ArenaVotingActive")
    if flag and flag.Value then return end
    -- rest unchanged
```

**`src/client/GUI/GuiManager/InitialiseGuiManager.client.luau`, lines 182-183:**

```lua
-- Before:
elseif (peek(GameStateValues.isVoting)) then
    GuiManager.PushCentreByName(MODAL_NAMES.VOTING_GUI)

-- After:
elseif (peek(GameStateValues.isVoting)) then
    local flag = ReplicatedStorage:FindFirstChild("ArenaVotingActive")
    if not (flag and flag.Value) then
        GuiManager.PushCentreByName(MODAL_NAMES.VOTING_GUI)
    end
```

---

## Step 5 — Studio: verify VoteSpawn orientation

No new Parts or Remotes needed. Just confirm `workspace.GeneralWorld.VoteSpawn`:
- Has its **forward (-Z)** direction pointing toward the open voting area
- At least 15 studs of clear space ahead for mannequins

`ArenaVotingActive` is created at runtime by the LocalScript.

---

## Verification Checklist

1. `print(outfit.votes)` inside `getUnseenOutfit` — confirm ascending order
2. `print("exclude:", excludeOutfitId)` server-side — second call shows champion ID
3. Voting starts → camera locks to judge POV; Voting ends → camera restores
4. Studio Explorer shows two Models under `workspace` during Voting (local client only)
5. Click mannequin → `SubmitVoteRF` fires → loser fades → winner slides → new challenger
6. Vote for right mannequin → it slides to left slot → new challenger enters right
7. Idle 10s → champion auto-wins → loop continues
8. Exhaust all outfits → `finishArena()` → camera restored, mannequins gone
9. HUD vote button click during Voting → VotingFrame does NOT appear
10. Two-client Studio test → each client sees only their own mannequins
