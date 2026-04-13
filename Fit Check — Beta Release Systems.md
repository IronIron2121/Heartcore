# Fit Check — Beta Release Systems Overview

## What is Fit Check?

Fit Check is a Roblox fashion competition game built around a repeating game loop. Players dress their avatars to match a theme during a timed dressing round, then vote on each other's outfits in a head-to-head voting round. Winners are announced during an intermission, and the loop repeats. The game is currently in active development, with a working core loop and several systems already implemented.

---

## What Is Already Built

The following systems are implemented and functional:

**Core Game Loop**
- State machine managing the full round cycle: Waiting → Dressing → Voting → Intermission
- Minimum player threshold before rounds begin
- Round timer, automatic state transitions, and per-state teleportation to dedicated map zones
- Auto-submission of outfits at the end of the dressing round if a player hasn't submitted manually

**Dressing Round**
- Wardrobe and catalog UI for browsing and equipping items
- Outfit submission system, including cooldown and confirmation
- Theme display bar showing the current round's theme and time remaining

**Voting Round**
- Per-player private 3D arenas ("colosseum") where two outfits are presented head-to-head
- Click-to-vote interaction with automatic vote if a player idles too long on a matchup
- "Winner stays on" structure — the winning outfit remains and faces a new challenger
- Real-time player sidebar showing all players' submission status during dressing, and vote-score rankings during voting

**Intermission**
- Podium system displaying the top-placing outfits from the previous round
- Winner announcement and podium model updates between rounds

**Progression**
- XP and levelling system (tiered XP curve, L1–100)
- XP awarded for submitting, voting, and placing
- Daily challenge system with progress tracking and reward claiming

**Infrastructure**
- GUI slot system with animated slide-in/out transitions for all HUD panels
- Modal stack manager for full-screen overlays (wardrobe, voting, FTUE, player inspection)
- Outfit serialisation/deserialisation for storing and loading HumanoidDescriptions
- Player data persistence via ProfileService
- Loading screen management

---

## Systems To Build

The following are the remaining systems required for a beta release, organised by area.

---

### 1. Round Transition Animations

**What it is:** Short animated wipes or swipe transitions that play when the game moves between states (e.g. Dressing → Voting, Voting → Intermission).

**What needs to be built:**
- A client-side transition controller that triggers on state changes
- Transition animations (swipe, fade, or similar) using Fusion Tweens or a dedicated animation module
- Integration with the existing state machine so transitions fire at the correct moment without delaying game logic

---

### 2. Intermission Overhaul

**What it is:** A more engaging intermission experience replacing the current static podium display.

**What needs to be built:**

- **Podium zoom sequence** — A scripted camera animation that zooms into the top 3 podium winners for approximately 3 seconds at the start of intermission. This requires a camera controller that temporarily overrides the player's camera, plays the zoom sequence, then returns control.

- **All-outfit podium display** — Currently only top placers appear on podiums. This needs to be extended so that all submitted outfits are displayed on podiums around the intermission zone during this phase.

- **Catalog re-enable** — The full wardrobe and catalog (browse, buy, try-on) should be accessible during intermission. This requires the catalog button and wardrobe modal to be conditionally enabled/disabled based on game state. Currently the catalog is always accessible; the dressing round will restrict it (see below), so intermission becomes the default "open" state.

- **Flair shop access** — A new shop UI for the Flair system (see section 6) should be accessible during intermission.

---

### 3. Dressing Round — Station System

**What it is:** A redesign of how players dress during the dressing round. Rather than accessing the full catalog via a UI button, players physically walk to stations placed around the map. Each station represents a clothing category (e.g. tops, bottoms, shoes, accessories), and only shows items from that category.

**What needs to be built:**

- **Station objects** — Physical in-world objects (or zones) for each clothing category, placed by the map designer. These need a proximity prompt or click detector to open the associated UI.

- **Per-category catalog filtering** — When a player opens a station, the catalog UI opens pre-filtered to that station's clothing type. The existing catalog and wardrobe system needs to support being opened in a "filtered mode" from an external trigger.

- **Catalog lockout** — The catalog button in the HUD must be hidden or disabled during the dressing round. Players can only access clothing through stations. (Note: a future flair unlock could re-enable the catalog button, but this is not in scope for beta.)

- **State-aware station activation** — Stations should only be interactable during the dressing round. During voting and intermission they should be inactive.

---

### 4. Voting Round Overhaul

**What it is:** A significant redesign of the voting experience. Rather than each player voting in their own private arena in isolation, voting becomes a shared, visible, social experience.

**What needs to be built:**

- **Simultaneous shared voting** — All players vote on the same pair of outfits at the same time, rather than individually. This requires the voting system to broadcast the current matchup to all players, collect votes, and advance when all votes are in (or the time limit expires).

- **Voting timer per outfit** — Each matchup has a 5–10 second timer. If a player does not vote before the timer expires, their vote is not counted for that round.

- **AFK detection and kick** — If a player misses 2–3 consecutive votes without interacting, they are kicked from the server. This requires a per-player missed-vote counter reset on each vote cast.

- **Player icon vote reveal** — The existing player sidebar shows player thumbnails. When a player casts their vote, their thumbnail should animate ("zoom") to sit beneath the outfit rig they voted for, making voting visible to everyone in real time.

- **Winner and loser animations** — At the end of each matchup, the winning outfit's rig plays a custom "winner" animation (e.g. cheering, taunting) and the losing rig plays a custom "loser" animation (e.g. comical death). These animations will be custom-built. The system needs:
  - An animation controller on voting rigs that can be triggered by the outcome
  - A brief animation playback window between matchups before advancing to the next pair

- **"Winner stays on" enforcement** — The winning outfit remains and faces the next challenger. This logic exists in the current per-player arena system and needs to be ported to the new shared voting model.

---

### 5. Stats Tracking (Backend)

**What it is:** Per-player lifetime statistics stored server-side. No frontend display is in scope for beta — this is data infrastructure for future use (leaderboards, profiles, achievements).

**Stats to track:**
- Total votes cast
- Total votes received
- Total outfit submissions
- Total wins (1st, 2nd, 3rd place finishes)
- Total rounds participated in

**What needs to be built:**
- Stats fields added to the player data profile (ProfileService schema)
- Increment calls wired into the relevant game systems (vote cast → increment votes cast; round end → increment wins for top 3, etc.)
- A server-side read API for future frontend consumption

---

### 6. Flair System

**What it is:** An in-game currency called Flair that players can earn through gameplay or purchase with Robux. In beta, Flair is used to purchase winner and loser animations for use during voting.

**What needs to be built:**

- **Flair currency** — A persistent Flair balance stored in each player's profile. Flair is awarded at round end (e.g. for placing, for participating) and can be purchased directly with Robux via Roblox's MarketplaceService (developer product flow).

- **Robux purchase flow** — Integration with `MarketplaceService:PromptProductPurchase` for Flair bundles. Requires developer products set up on the Roblox game page, a `ProcessReceipt` handler on the server, and receipt deduplication to prevent double-granting on network failure.

- **Flair shop UI** — A shop modal accessible during intermission. Shows available animations with their Flair prices, the player's current balance, and a purchase/equip flow. Purchased animations are stored in the player's profile.

- **Animation equip and application** — Players equip a winner animation and a loser animation from their owned collection. These are applied when the voting outcome triggers the animation controller (see section 4).

- **Earn-through-gameplay rewards** — Flair granted at round end based on placement and participation. This ties into the existing XP reward hooks in the game loop.

---

## Summary Table

| System | Status |
|---|---|
| Core game loop (state machine, timers, teleport) | ✅ Built |
| Dressing round — wardrobe & catalog UI | ✅ Built |
| Voting round — per-player private arena | ✅ Built |
| Intermission — basic podiums & winner display | ✅ Built |
| Player sidebar (submission status + vote rankings) | ✅ Built |
| XP & levelling | ✅ Built |
| Daily challenges | ✅ Built |
| Round transition animations | 🔲 To build |
| Intermission overhaul (zoom, all outfits, catalog re-enable) | 🔲 To build |
| Dressing stations (physical map stations, catalog lockout) | 🔲 To build |
| Voting overhaul (simultaneous, animations, AFK kick, icon zoom) | 🔲 To build |
| Stats tracking (backend) | 🔲 To build |
| Flair system (currency, Robux purchase, shop, animations) | 🔲 To build |
