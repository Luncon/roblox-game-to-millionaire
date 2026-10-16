# Proposal

## Why

Solo play currently has no enemy army to fight. Three reusable neutral opponents in the battlefield center will make player melee, troop combat and army orders easier to test.

## What Changes

- Confirmed: spawn three generic warriors near the battlefield center, two melee and one ranged, attackable by all civilizations.
- Confirmed: each dead warrior respawns independently after ten seconds.
- Proposed defaults: enemies fight back, share one neutral faction, use basic level-one combat stats and give the existing ten-coin final-hit reward.
- Use generic procedural rigs with clear neutral labels and simple weapons. Keep them near the center and retain settlement protection.
- Enable this test opposition in the prototype through one server configuration switch, independent of player claims, upgrades and civilization changes.
- Outside scope: formations, additional player army slots, new progression, saved neutral enemies, matchmaking and new rewards.

## Capabilities

### New Capabilities

- `neutral-battlefield-opponents`: Server-owned shared test opponents, universal civilization hostility, combat and independent respawning.

### Modified Capabilities

None. The main spec inventory currently contains only development-workflow; existing combat behavior is recorded in active change specs.

## Impact

- Extend CombatService and CombatRules to admit explicitly registered neutral actors while retaining player claim, arena, ownership and profile checks.
- Add a small neutral-opponent service and configuration; connect it to CivilizationService's shared combat instance and shutdown lifecycle.
- Reuse procedural rig construction, WarriorNavigator, animation and TroopProjectile where practical without importing custom civilization models or modifying source templates.
- Add isolated combat and lifecycle fixtures plus Studio solo verification using a fake profile store. Update army and playtest documentation when implemented.
- No new dependencies, remotes, profile fields, storage keys or schema changes.
