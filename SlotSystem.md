# VoteBarManager — Slot System Design

## Overview

Three icon bars exist on screen simultaneously. Player thumbnails live in the **bottom bar** by default and spring to the **left or right bar** when vote results are revealed, then return to the bottom bar when the next matchup begins.

---

## The Three Bars

### Bottom Bar
- N slots (one per player, up to max player count)
- Default home for all thumbnails between matchups
- Thumbnails sit here during active voting

### Left Bar
- N slots, stacked with overlap, anchored to the left side of the screen
- Thumbnails move here when the player voted for the **champion** (left mannequin)

### Right Bar
- N slots, stacked with overlap, anchored to the right side of the screen
- Thumbnails move here when the player voted for the **challenger** (right mannequin)

---

## Slot Stacking Pattern

Slots overlap to form a fan. For the **left bar**:
- Slot 1: anchor point `(1, 0.5)`, positioned at the rightmost edge of the bar
- Slot 2: anchor point `(1, 0.5)`, positioned 1/3 of a slot width to the left of slot 1
- Each subsequent slot steps further left by the same amount
- 8 slots total

The **right bar** mirrors this exactly.

---

## Thumbnail Positioning

Each thumbnail has a reactive `targetX` and `targetY`. A spring drives the thumbnail toward its target each frame. To move a thumbnail, update **both** values — X alone is not enough since the side bars sit at a different vertical position than the bottom bar.

---

## Remotes

| Remote | Direction | Purpose |
|--------|-----------|---------|
| `VoteSubRoundCompleteRE` | Server → All Clients | Fires when matchup ends; carries `{[userId]: "left"\|"right"}` mapping so clients can animate thumbnails to their vote side |
| `RestoreVoteIconsRE` | Server → All Clients | Fires when the new challenger is ready; clients reset all thumbnails back to the bottom bar |

---

## Data Flow

1. Matchup ends (timer or all voted)
2. Server builds `{[userId]: side}` from `currentVotes` — map each `outfitId` to `"left"` (champion) or `"right"` (challenger)
3. Server fires `VoteSubRoundCompleteRE` with that mapping
4. Client iterates the mapping **sorted by userId** (guarantees consistent slot assignment across all clients) and sets each thumbnail's `targetX`/`targetY` to the next available slot on the appropriate side
5. Short hold so players can read the result
6. Death animation plays
7. New challenger mannequin spawns
8. Server fires `RestoreVoteIconsRE`
9. Client resets all thumbnails back to their bottom bar slots

```lua
-- Pseudocode (client-side, on VoteSubRoundCompleteRE)
local sorted = -- voteMap entries sorted by userId
local numLeft, numRight = 0, 0

for _, entry in sorted do
    if entry.side == "left" then
        numLeft += 1
        thumbnails[entry.userId].targetX = leftSlots[numLeft].X
        thumbnails[entry.userId].targetY = leftSlots[numLeft].Y
    elseif entry.side == "right" then
        numRight += 1
        thumbnails[entry.userId].targetX = rightSlots[numRight].X
        thumbnails[entry.userId].targetY = rightSlots[numRight].Y
    end
end
```

---

## Sequence of Events (per matchup)

1. Voting timer expires or all players vote
2. Server fires `VoteSubRoundCompleteRE` with vote mapping
3. Client springs thumbnails to left/right slots
4. Short hold (~1s)
5. Death animation plays on losing mannequin
6. Winner slides to champion slot; new challenger spawns
7. Server fires `RestoreVoteIconsRE`
8. Client springs all thumbnails back to bottom bar

---

## Edge Cases

| Case | Handling |
|------|----------|
| Player did not vote | Thumbnail stays in bottom bar; omit from the mapping sent via `VoteSubRoundCompleteRE` |
| Fewer players than slots | Unused slots are never assigned |
| Player disconnects mid-matchup | Their thumbnail is removed; remaining slots re-pack |
