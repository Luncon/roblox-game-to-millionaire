# Proposal

## Why

Players need active weapon skills that make melee combat more expressive as their existing upgrades progress. Deliver weapon-family skills first; combat and transport animals remain phase two, with civilization-specific specials and customizable elemental effects deferred.

## What Changes

- Confirmed: spear/javelin Dash Thrust, axe Whirlwind and sword Double Slash are shared by all civilizations and all eligible players/troops based on their actual weapon family.
- Confirmed: buy skill tiers I–V at weapon levels 10/20/30/40/50, requiring Training Camp I (the existing Training Yard I purchase). Tier prices are 100/200/350/550/800 coins, totaling 2,000 per civilization track.
- Confirmed: show only the next eligible physical skill pad beside the training camp; purchases apply to matching living and replacement troops without healing or resetting cooldowns.
- Confirmed: cooldowns are 8 seconds for dash, 12 for spin and 9 for double slash. Damage and bounded geometry follow design.md and the weapon-effects spec.
- Confirmed: skills replace ordinary attacks during their active animation, with immediate startup and no recovery pause, grant no invulnerability or stun, and spend cooldown on accepted activation even on a miss. NPCs activate automatically when appropriate; players have an accessible action control.
- Phase two: preserve the civilization-mounts specification as a future combat/transport contract. Do not implement mounts during phase one. Mount-specific tuning remains provisional until phase-two planning.
- Deferred beyond this first skill milestone: civilization-specific specials, burning/slow effects, selectable palettes and ultimates. Bows, muskets, slings and crossbows receive no new skill yet; ranged axe/javelin wielders can use the corresponding close-range skill.

## Capabilities

### New Capabilities

- `weapon-effects`: phase-one shared weapon-family skills, paid tiers, physical pads, combat and persistence.
- `civilization-mounts`: phase-two combat and transport mounts; retained future contract, excluded from phase-one completion.

### Modified Capabilities

None. The only main spec is development-workflow; existing implemented gameplay contracts remain in their change artifacts.

## Impact

Extend shared configuration, CombatService/CombatRules, PlayerCombatService, troop encounter/projectile coordination, Economy/ProfileData/ProfileService, physical pads and client input/feedback. Preserve gear curves, existing fourteen save fields, version-one keys/scopes, protection, exactly-once kill rewards, source models and troop timers. Add one missing-default skillLevel field per civilization. No dependencies or animal assets are needed in phase one. Studio runtime checks are required; specification validation and Rojo builds alone cannot establish gameplay correctness. Do not archive this combined change as complete while phase two remains pending.
