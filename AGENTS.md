# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Build & Development Commands

```bash
# Build the Roblox place file from source
rojo build -o "Tastemaker_New.rbxlx"

# Start Rojo live-sync server (run while Roblox Studio is open)
rojo serve

# Install/update toolchain (Rojo)
aftman install
```

## Project Architecture

**Game Type:** Roblox fashion game with timed contest loops

**Tech Stack:**
- Luau (Roblox's typed Lua variant)
- Fusion 0.3 for reactive UI (`src/repstore/Utility/Fusion/`)
- ProfileService for player data persistence
- Rojo for source control and project management

**Source Structure:**
- `src/client/` → StarterPlayerScripts (client-only scripts)
- `src/server/` → ServerScriptService (server-only scripts)
- `src/repstore/` → ReplicatedStorage (shared modules, UI, utilities)
- `default.project.json` defines the Rojo sync mapping

### Game Loop System

**11-minute cycle managed by state machine:**
1. **Dressing (7min):** Players submit outfits matching a theme
2. **Voting (3min):** "This or That" pairwise voting (winner stays left, loser drops out, new challenger enters right)
3. **Intermission (1min):** Winners announced, podiums updated

**Key Modules:**
- `GameStateManager` (`src/repstore/GameLoop/`) — State machine, timer, theme selection
- `GameOutfitManager` (`src/repstore/GameLoop/`) — Outfit submissions, vote/view tracking
- `WinnersManager` (`src/server/Voting/`) — Podium models, leaderboard
- `DataManager` (`src/server/Data/`) — Player XP, levels, ranks via ProfileService
- `Inspector` (`src/client/Mannequins/Inspector/`) — Mannequin/player inspection with loading state
- `LoadingScreenManager` (`src/repstore/Libraries/`) — Centralized loading screen management
- `ClientOutfitService` (`src/repstore/Utility/`) — Client-side outfit save/delete operations
- `SerialisationService` (`src/repstore/Utility/`) — HumanoidDescription serialization/deserialization

**Cross-Script Communication:**
- Replicated ValueObjects in ReplicatedStorage:
  - `CurrentStateName` (StringValue)
  - `CurrentThemeName` (StringValue)
  - `SecondsRemaining` (IntValue)
- Read these Values directly instead of requiring managers to avoid circular dependencies

### UI Architecture

**GuiManager** (`src/repstore/Libraries/GuiManager/`) provides modal stack system:
- Register modals with `GuiManager.RegisterModal(MODAL_NAMES.X, frame, initCallback)`
- Open/close with `GuiManager.OpenModal()` / `GuiManager.CloseModal()`
- Push notification modals with `GuiManager.PushNotificationCentre(name, message, onConfirm)`
- Pop with `GuiManager.PopCentre()`
- Automatic blur effect on modal open
- Modal names defined in `MODAL_NAMES.luau`

**GuiConfiguration** (`src/repstore/Libraries/GuiManager/GuiConfiguration.luau`):
- Manages HUD layouts with 5 slots: TopMiddle, TopRight, BottomLeft, BottomMiddle, BottomRight
- Each slot is a Frame with position animated via Fusion Tweens (slides in/out)
- Elements are reparented into slots on `Enable()` — Roblox instances can only have one parent, so shared elements (e.g. buttons HUD) are reparented between configurations rather than duplicated
- `GuiConfiguration.new(scope, props)` accepts slot elements and position overrides
- `Enable()` / `Disable()` toggle visibility via an `Enabled` Fusion Value

**LoadingScreenManager** (`src/repstore/Libraries/LoadingScreenManager.luau`):
- Centralized loading screen management — avoids repeating LoadingScreen boilerplate across components
- Parent-based API: `LoadingScreenManager.show(parent)` / `LoadingScreenManager.hide(parent)`
- Internally caches LoadingScreen instances keyed by parent GuiObject
- First `show()` creates a LoadingScreen with `parent = parent`; subsequent calls toggle visibility
- Uses the `LoadingScreen` widget from `src/repstore/UI/FusionComponents/Widgets/LoadingScreen.lua`

**Fusion 0.3 Component Pattern:**
```lua
local function MyComponent(
    scope: Fusion.Scope,
    props: {
        someValue: UsedAs<string>,
        onClick: (() -> ())?,
    }
): Fusion.Child
    return scope:New "Frame" {
        -- properties with reactive bindings
    }
end
```

**Key Fusion Patterns:**
- `scope:Value(initial)` — Mutable state, update with `:set(newValue)`
- `scope:Computed(function(use) ... end)` — Auto-calculated reactive state
- `scope:Tween(stateObject, tweenInfo)` — Animate state changes
- **IMPORTANT:** Roblox ValueObjects (StringValue, IntValue, etc.) are NOT Fusion Values
  - Cannot use `use(SomeValueObject.Value)` directly in Computed
  - Bridge them: create a Fusion Value and sync with `.Changed` event

### Data & Progression

**ExpConfig** (`src/repstore/Libraries/ExpConfig`) defines:
- Tiered XP curve (L1-10: 250xp, L11-20: 400xp, ..., L91-100: 1200xp)
- Total XP to max level: 68,500
- Rewards: Submit=1xp, Vote=0.1xp, Placements: 1st=10xp, 2nd=5xp, 3rd=3xp

## Code Style & Conventions

**File Extensions:**
- `.luau` — Files using strict typing with `--!strict`
- `.lua` — Files without strict mode

**Strict Mode:**
- Prefer `--!strict` at the top of new files
- Type all function parameters and returns when possible

**Fusion Components:**
- Always accept `scope: Fusion.Scope` as first parameter
- Use `UsedAs<T>` type for props that can be reactive or static
- Return `Fusion.Child` for components that integrate with Fusion's children API
- Components can return multiple values (e.g., `(Frame, Controls)` tuple)

**Naming:**
- Services folder: `GameLoop/`, `Data/`, `Voting/`
- Utility modules: PascalCase (e.g., `MannequinFactory`, `ShopUtilities`)
- UI Components: PascalCase (e.g., `AccessoryTile`, `DropdownButton`)

## Common Gotchas

**Watch for typo:** `odtfitId` → `outfitId` (avoid this common mistake)

**Roblox API:**
- Use `CreateHumanoidModelFromDescription` (NOT `...Async`)
- Requires `HumanoidRigType` parameter

**Roblox Instance single-parent constraint:**
- An Instance can only have one `Parent` at a time
- To share a UI element across multiple containers, reparent it (set `.Parent`) when switching — do not duplicate
- When reparenting during animated transitions, delay the reparent until the old container has animated off-screen

**UIGridLayout / UIListLayout constrains all sibling GuiObjects:**
- If you need a child (e.g. LoadingScreen overlay) that shouldn't be constrained by a layout, parent it to a frame *above* the layout container
- Example: `LoadingScreenManager.show(wardrobeContainer)` instead of `show(catalogContainer)` when catalogContainer has a UIListLayout

**Fusion + Roblox ValueObjects:**
```lua
-- ❌ WRONG: Cannot use Roblox ValueObjects directly in Fusion
local isOpen = scope:Computed(function(use)
    return use(CurrentStateName.Value) == "Dressing"
end)

-- ✅ CORRECT: Bridge with Fusion Value + Changed event
local currentState = scope:Value(CurrentStateName.Value)
CurrentStateName.Changed:Connect(function(newValue)
    currentState:set(newValue)
end)
local isOpen = scope:Computed(function(use)
    return use(currentState) == "Dressing"
end)
```

**Fusion Tween:**
```lua
-- Pattern 1: Tween a Value (manual control)
local posValue = scope:Value(UDim2.fromScale(0, 0))
local posTween = scope:Tween(posValue, TweenInfo.new(0.5))
Position = posTween  -- Pass the Tween, not the Value
posValue:set(UDim2.fromScale(1, 1))  -- Set the Value to animate

-- Pattern 2: Tween a Computed (reactive animation)
Position = scope:Tween(
    scope:Computed(function(use)
        return if use(isVisible) then CENTRE else OFFSCREEN
    end),
    TweenInfo.new(0.5)
)
```

**StarterGui:SetCore:**
- `SetCore("PromptSendFriendRequest", player)` requires player argument

**Avoid hardcoded values:**
- Use `player.UserId` not hardcoded IDs in thumbnail fetches
- Use ReplicatedStorage Values for shared state instead of cross-requiring managers

**Wrap RemoteEvent/RemoteFunction calls in `callWithRetry`:**
- Remote invocations (e.g. `RemoteFunction:InvokeServer()`) can fail due to network issues
- Always wrap them in `callWithRetry` — the key benefit is the `pcall` it uses internally, which prevents the caller from erroring out; the retry is a bonus
- Example: `callWithRetry(function() return MyRemoteRF:InvokeServer(args) end)`

**Luau strict-mode type casting for OOP:**
- When returning `self` from a method and strict mode complains about types, use the double-cast pattern: `(self :: any) :: MyType`
- Single cast `self :: MyType` may fail with "types are unrelated"

**Server-side asset caching for client use:**
- `InsertService:LoadAsset` is server-only — clients cannot call it
- Pattern: server loads the asset, caches it to a ReplicatedStorage folder (e.g. `ReplicatedStorage.Emotes`), client reads from that folder
- Expose a RemoteFunction so the client can request the server to load+cache on demand
- Example: `ServerCustomisationService.LoadEmote(itemId)` caches to `Emotes` folder, client invokes `LoadEmoteRF` then reads from `Emotes:FindFirstChild(tostring(id))`

**Async loading pattern:**
- To make GUI feel responsive, show the frame immediately (e.g. via GuiManager modal push), then `task.spawn` the heavy async work (API calls, model creation)
- Show a loading screen via `LoadingScreenManager.show(container)` while loading, hide when done
- This prevents the GUI from appearing to hang while data loads
