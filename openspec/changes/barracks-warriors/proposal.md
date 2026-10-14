# Proposal

## Why

Players can build settlements but cannot field an army. Add the first automatic
warrior and real NPC combat so the central battlefield becomes playable.

## What Changes

- Unlock a civilization-themed level-one barracks at settlement level 2.
- Automatically maintain one melee warrior per eligible owner. Spawn the first
  unit on unlock; replace a dead warrior 15 seconds after death. These limits
  and melee-only behavior were confirmed by the user.
- Warriors leave their barracks, navigate to the middle, and fight enemy NPCs
  and claimed players within the battlefield. Owners, friendly troops, neutral
  players, and actors outside the arena remain protected.
- Show warrior status and respawn countdown, with health and combat feedback.
- Apply the owner's weapon and armor tiers to both the living warrior and its
  replacements. Live upgrades preserve the unit and its missing-health deficit;
  purchases during a replacement countdown do not change its deadline.
- Proposed initial tuning: 100 HP, 10 damage, 1-second attack cooldown, 5-stud
  melee reach, 35-stud detection, movement speed 12. Initial deployment is free.
- Keep progression session-only. Higher barracks levels, ranged classes,
  formations, player-controlled weapon attacks, combat rewards, and saving
  are outside this milestone.

## Capabilities

### New Capabilities

- `barracks`: settlement unlock, automatic one-slot deployment and respawning.
- `warrior-combat`: themed melee NPCs, autonomous navigation, hostile targeting,
  authoritative damage, arena protection, and cleanup.

### Modified Capabilities

None in the main spec inventory. Existing in-flight economy and claim behavior
remains intact; barracks eligibility consumes the confirmed settlement level.

## Impact

Shared warrior tuning, a reusable character equipment boundary, NPC rig creation,
server army/navigation/combat, settlement buildings and spawn transforms, owner
HUD, Studio tests and playtest documentation. No external assets, dependencies,
currency prices, or persistent profiles change.
