# Tasks

## 1. Progression and floor unlocks

- [x] 1.1 Add softer gear tiers, barracks progression and fixed kill credits; verify exact values, price/gate rejection, coin caps and copied account states in Studio specs.
- [x] 1.2 Add actual settlement-unlocked tier pads and dynamic input binding; verify new instances, retired/locked purchases, ownership, entry latches and all-civilization geometry.
- [x] 1.3 Update economy documentation with balance, prices and unlock stages; check values against the delivered configuration.

## 2. Shared combat and player attacks

- [x] 2.1 Implement registered-actor damage and exactly-once final-hit rewards; verify hostile kills, assists, blocked/environmental/stale/friendly deaths and reward publication in focused Studio tests.
- [x] 2.2 Add player weapon input and validated melee; verify equipped and unequipped attacks, range, direction, cooldown, arena protection, character reset and real input in a small client test.
- [x] 2.3 Document player combat controls and reward rules; verify documentation matches the server boundary.

## 3. Barracks and ranged troops

- [x] 3.1 Add civilization ranged gear/rigs and independent two-slot lifecycle; verify all 13 variants, inherited tiers, cap transition and pending-deadline preservation.
- [x] 3.2 Add visible bounded projectiles and ranged navigation/targeting; verify real flight, enemy impact, obstacles, immunity, cleanup and final-hit rewards in Studio.
- [ ] 3.3 Update barracks signs, HUD tier/capacity/countdowns and army documentation; observe the delivered progression and feedback in a running client.

- [x] 3.4 Integrate five user-provided melee model assets; verify each uses its custom template, preserves source cosmetics and originals, walks under real Humanoid physics, and receives tier upgrades.

- [x] 3.5 Incorporate civilization and owner identity into themed main-hall facades; verify all 13 styles, rebuilds, release markers and unobstructed controls.

## 4. Integration

- [x] 4.1 Run focused regression and small multiplayer checks, resolve independent reviewer findings, and record exact runtime evidence and remaining limitations.
- [x] 4.2 Build production and isolated test places, validate strict OpenSpec, and verify temporary test content is excluded from production and removed from Studio.

## Verification follow-up

92 Studio module cases, 31 focused three-client runtime cases, and 43
multiplayer/native-input cases passed. Both final Rojo builds and strict OpenSpec
validation passed. Test content was excluded from production and temporary
Studio content removed. Independent review findings were resolved.

Task 3.3's implementation is delivered; visual inspection of the level-IV
independent countdown HUD on device viewports remains for the next session.
Eight-player testing remains canceled by the user. Progress remains session-only.
