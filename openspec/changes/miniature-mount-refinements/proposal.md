# Proposal

## Why

Playtesting exposed mount proportions, seating and facial details that need correction.
Troops also disappear immediately on death; the user requests ragdolls for both riders and animals.

## What Changes

- Make elephants and camels slightly slower than regular troops; use a chosen speed of 5.5 versus 6 studs per second.
- Reduce elk size, make bears only slightly smaller, seat lion riders on their backs, reshape bull feet, animate crocodile limbs, add wolf/rhino eyes and a simple recognisable rhino snout.
- Show bounded cosmetic physical ragdolls on confirmed troop deaths, including mounted animals and their riders, while preserving authority, respawn timers, selection and capture rules.
- Remove the fixed count limits on placed structures and held building items, as subsequently requested; retain legal plot geometry, item-specific uniqueness, stock, currency and the ten-slot army cap.

All visual corrections, slower elephant/camel movement and ragdolls are confirmed requirements.
Exact sizes, gait amplitudes, 5.5 speed and a short corpse lifetime/budget are implementation choices.
Player deaths, ride controls, new abilities, balance changes beyond species speed, production code and real storage are outside scope.

## Capabilities

### New Capabilities

- `miniature-mount-presentation`: species proportions, grounded seating, facial geometry, gait and species speed.
- `miniature-death-ragdolls`: exact-life cosmetic death presentation, physical articulation and bounded cleanup.
- `miniature-structure-capacity`: building ownership and placement without arbitrary structure/item count ceilings.

### Modified Capabilities

None. The mounted-army foundation remains an unarchived change, not an implemented main specification.

## Impact

Isolated miniature mount configuration/factories, shared authoritative profile lookup, death presentation and renderer lifecycle, native/pure regressions, generated review builds and Obsidian notes. Imported source templates stay immutable; no new dependencies or saved fields are introduced.
