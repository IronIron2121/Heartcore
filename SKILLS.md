# SKILLS.md

## Shorten Require Paths

**When to apply:** A Luau script has `require()` calls using long chained paths like `ReplicatedStorage.DataTables.ImageUris` or `StarterPlayer.StarterPlayerScripts.GUI.FtuePop`.

**Pattern:**
1. Look at all `require()` calls and identify repeated parent paths that aren't already captured in the `-- Folders` section.
2. Add those parents as local variables under `-- Folders`, using `:WaitForChild()` for top-level children or dot access for deeper nesting that's already safe.
3. Replace the long paths in `require()` calls with the new short folder references.

**Before:**
```lua
-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")

-- Modules
local ImageUris = require(ReplicatedStorage.DataTables.ImageUris)
local UI_CONSTANTS = require(ReplicatedStorage.Utility.UI_CONSTANTS)
local FtuePop = require(StarterPlayer.StarterPlayerScripts.GUI.FtuePop)
```

**After:**
```lua
-- Folders
local Libraries = ReplicatedStorage:WaitForChild("Libraries")
local DataTables = ReplicatedStorage:WaitForChild("DataTables")
local Utility = ReplicatedStorage:WaitForChild("Utility")
local ClientGUI = StarterPlayer.StarterPlayerScripts.GUI

-- Modules
local ImageUris = require(DataTables.ImageUris)
local UI_CONSTANTS = require(Utility.UI_CONSTANTS)
local FtuePop = require(ClientGUI.FtuePop)
```

**Rules:**
- Only add a folder variable if it shortens at least one require (don't add unused folders)
- Keep folder variables grouped under the `-- Folders` comment block
- Top-level folders (direct children of services like `ReplicatedStorage`, `StarterPlayer`) **must** use `:WaitForChild()` — these may not be loaded yet at require time
- Anything below a folder that's already been `WaitForChild`-ed can be accessed with `.` notation (e.g. `UI.FusionComponents`, `FusionComponents.Widgets`)
- Within each subcategory (`-- Folders`, `-- Modules`, `-- Remotes`, etc.), sort lines in descending order of length
- Respect dependency ordering: a parent variable must appear before any variable that references it (e.g. `Libraries` before `GuiManagerLibrary = Libraries:WaitForChild("GuiManager")`)

---

## Extract Shared Fusion State into a Module

**When to apply:** Two LocalScripts need to read or write the same reactive Fusion `Value` (e.g. a HUD counter driven by one script and displayed by another).

**Pattern:**
1. Create a ModuleScript in `ReplicatedStorage` (e.g. `ArenaTimerHud.luau`)
2. Inside, create the Fusion scope and `Value` objects at module level
3. Export the frame and any setter functions — do **not** export the raw `Value` (callers use setters)
4. Both LocalScripts `require()` the module — Roblox's cache returns the same table, so both share the same Values

```lua
-- ArenaTimerHud.luau
local scope = Fusion:scoped()
local timerCount = scope:Value(0)
local waitingMode = scope:Value(false)

local frame = scope:New "Frame" { ... }

local function setTimer(n: number) waitingMode:set(false); timerCount:set(n) end
local function setWaiting() waitingMode:set(true) end

return { frame = frame, setTimer = setTimer, setWaiting = setWaiting }
```

**Rules:**
- Only works within the same Lua VM (LocalScripts on the same client) — does not cross client/server
- Keep the raw `Value` objects private; expose typed setter functions so callers can't accidentally break invariants
- The module must live in `ReplicatedStorage` (or another replicated location) so both scripts can reach it
