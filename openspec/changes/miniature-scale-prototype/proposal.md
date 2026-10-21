# Proposal

## Why

The user is redesigning the game around a normal-sized commander and miniature civilization cities and armies. Establish scale, movement, readability and building inspection in a small playable scene before implementing the new economy.

## What Changes

- Add a separate Studio prototype with one Spartan house, farm and barracks, miniature workers and patrolling soldiers, and a normal-sized unarmed avatar.
- Start at quarter scale with scaled routes and nonblocking scenery/units; provide walk/overview camera controls and clickable building information.
- Confirmed direction: players do not fight. Prototype players receive no weapons or combat input.
- Keep the existing production build, checkpoint and player profiles intact. No production bootstrap, economy or saved-data migration changes in this slice.
- Proposed scene defaults: Sparta, four soldiers, two workers, quarter scale. These are test-scene tuning rather than progression promises.
- Out of scope: purchases, placement, production rewards, restocking shops, research, larger armies, active battles, conquest, trading and the shared Black Market.

## Capabilities

### New Capabilities

- `miniature-preview`: isolated miniature civilization scene, normal-scale commander, movement and building/camera inspection.

### Modified Capabilities

None. The main spec inventory currently contains development-workflow only.

## Impact

New prototype-specific Rojo project and scripts, reusing sanitized existing troop/equipment assets, plus native Studio checks and setup notes. No dependencies, new authoritative gameplay remotes, production source edits or publication.
