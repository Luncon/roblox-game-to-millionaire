# Proposal

## Why

Leaving currently resets all civilization progress and players cannot switch civilization. Save each civilization independently so players can return to an established settlement or start another without losing their earlier work.

## What Changes

- Save each player's coins, settlement, weapon, armor and barracks levels separately for every civilization, as requested.
- Load before allowing claims or economic mutations; distinguish a genuinely new profile from a failed or invalid load.
- Add a civilization switch control and saved-progress previews. Switching to a free civilization keeps the player's plot; occupied choices preserve the current civilization and progress.
- Restore buildings, gear, floor controls and army capacity from the selected civilization's saved levels. Active NPC identities, health, positions and pending timers are not persisted.
- Add periodic and final saves with ordered retries and an exclusive expiring session lease. A lost lease prevents further progress mutations.
- Finish the previous milestone's level-IV army HUD and countdown layout check.

Confirmed behavior is independent civilization progress and leave/rejoin restoration. The one-key profile schema, 30-second autosave and 120-second lease are implementation choices. Cross-server routing, formations, abilities, more tiers, monetization and eight-player testing remain outside this milestone.

## Capabilities

### New Capabilities

- `civilization-profiles`: validated per-player/per-civilization persistent progress with safe load, session ownership and final save behavior.
- `civilization-switching`: available-civilization switching, saved-progress previews and rebuilt gameplay state without losing an occupied claim.

### Modified Capabilities

None in the main spec inventory. This supersedes session-only behavior and immutable civilization selection in the implemented in-flight changes.

## Impact

New profile schema/service; Economy import and mutation gating; atomic ClaimRegistry switching; CivilizationService lifecycle and private snapshots; selector/HUD; isolated test bootstrap and fake datastore; Studio/runtime and real persistence checks; setup and gameplay documentation. No new dependencies. Studio development saves are isolated from live profiles.
