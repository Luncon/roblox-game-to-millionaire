# Tasks

## 1. Shared neutral combat

- [x] 1.1 Add failing isolated fixtures for explicit neutral registration, all-civilization hostility, neutral friendliness, unchanged player protections and normal final-hit reward; verify failures against current combat in Studio using a fake profile store.
- [x] 1.2 Implement explicit neutral CombatService records, shared hostility checks and fixed neutral attack stats; integrate targeting and projectile validation, then verify the new fixtures and existing combat/reward/projectile specs pass.
- [x] 1.3 Document neutral faction behavior and basic stats in docs/ARMY.md; verify the text matches the delta spec and passing combat fixtures.

## 2. Center opponents and respawning

- [x] 2.1 Add a generic procedural rig entry point and simple neutral sword/bow visuals; verify rig fixtures cover health, labels, classes and immutable civilization templates.
- [x] 2.2 Add configurable NeutralOpponentService with two melee slots and one ranged slot, terrain-grounded center spawns, pursuit and idle return; verify a solo fake-store runtime fixture observes all three classes and native melee/projectile attacks.
- [x] 2.3 Implement independent ten-second respawns and teardown guards; verify staggered deaths, no early respawn, no duplicate replacements, unchanged surviving rigs, projectile/corpse cleanup and no respawn after shutdown.
- [x] 2.4 Wire the enabled prototype configuration and service into CivilizationService startup/shutdown; verify disabling it prevents spawning and switches, upgrades and owner orders leave neutral slots and deadlines unchanged. Document the toggle and respawn behavior in docs/ARMY.md.

## 3. Integrated verification

- [x] 3.1 Run npm run check and the isolated Studio regression suite; record commands and results in docs/PLAYTEST.md without accessing real player storage.
- [x] 3.2 Use one solo Studio playtest to verify center appearances, player and owned-troop attacks, retaliation, ten-coin rewards and separate ten-second replacements. Exercise all thirteen civilizations with fake profiles, verify protection and existing army commands/caps, and record runtime evidence and any unavailable checks in docs/PLAYTEST.md.
