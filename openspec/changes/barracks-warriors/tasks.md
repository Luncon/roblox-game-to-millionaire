# Tasks

## 1. Rules, rigs, and inherited equipment

- [x] 1.1 Add warrior tuning, melee variants, and combat boundary rules; verify invalid inputs, transformed arena bounds, ownership, and range in Studio specs.
- [x] 1.2 Build R6 warrior rigs and shared equipment updates; verify all civilizations and tiers, real joints, damage, and missing-health preservation.
- [x] 1.3 Document warrior tuning and gear inheritance in docs/ARMY.md; check documented values against UpgradeTracks.

## 2. Barracks and automatic lifecycle

- [x] 2.1 Add themed stage-two barracks and transformed spawn API; verify stages 1–4, bounds, and existing pad clearance.
- [x] 2.2 Add one-slot deployment, exact 15-second replacement, live gear refresh, release cleanup, and owner HUD; verify live identity, pending deadlines, resets, and leave/reclaim behavior in Studio.
- [ ] 2.3 Document barracks controls and timing in the playtest guide; verify HUD and countdown in a running client.

## 3. Autonomous combat

- [x] 3.1 Implement bounded asynchronous navigation and server-owned NPC physics; verify real movement from village and citadel into the arena.
- [x] 3.2 Implement hostile acquisition, authoritative melee, cooldown, line of sight, and protected actor rules; verify NPC combat and enemy player damage with owner, neutral, and outside-arena immunity.
- [x] 3.3 Review lifecycle and combat boundaries with the reviewer and resolve material findings; record remaining runtime limitations.

## 4. Integration checks

- [x] 4.1 Run existing and new Studio suites plus multiplayer integration; verify economic upgrades, character resets, army inheritance, and cleanup together.
- [x] 4.2 Build production and test projects and run strict OpenSpec validation; verify test scripts are excluded from production and update project documentation to match delivered behavior.
- [ ] 4.3 Run the requested eight-player Studio test with eight distinct civilization selections, native coin/upgrade inputs, inherited warrior gear, navigation, combat, unit caps, and replacements; record actual results and any startup failures.

## Verification follow-up

- The user chose to stop further eight-player testing and continue development
  after reporting a successful manual three-player NPC playtest. Task 4.3 remains
  unverified; startup failures are recorded in docs/PLAYTEST.md. The new HUD's
  device/layout observation in 2.3 also remains outstanding. Existing 69 module,
  14 army runtime, and 34 economy/multiplayer cases passed. Temporary Studio test
  objects were removed and graphics quality restored to Automatic.
