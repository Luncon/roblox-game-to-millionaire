# Civilization tycoon prototype

Connect Rojo to Studio and press Play. The map is generated at runtime inside
`Workspace.CivilizationPrototype`; it disappears when Play stops. Existing
Workspace objects are preserved. Large existing objects may cover the prototype.

1. Choose any of the 13 civilizations. Your character moves to a numbered settlement,
   its main building shows your civilization and display name, and a HUD shows your plot.
2. Reset your character. You should return to the same plot with the same HUD.
3. Start a Studio server with two clients. Have both choose Sparta: only one
   should succeed; the other can choose Britain on a different plot.
4. Disconnect the Spartan owner. A new client can select Sparta and reuse its plot.
5. Click the gold ground button or use its prompt: each accepted activation adds
   one coin. At level one only coin and settlement pads exist. Expand to level two
   to reveal weapon, armor, and barracks upgrade pads. Each track is capped by
   the settlement level.
6. Walk onto an affordable upgrade pad, stay on it, then exit and re-enter.
   Standing should not buy multiple upgrades.
7. Reset after upgrading. Coins, all levels, armor, and the equipped weapon
   should be restored for this session.
8. Try a phone viewport and a controller. The selector scrolls and the HUD only
   displays progress. Ground prompts support alternate input.
9. Upgrade the settlement to stage 2. A barracks appears and deploys one melee
   warrior automatically. Watch it walk to the central arena.
10. Buy separate weapon and armor upgrades. Your living warrior should receive
    the matching civilization gear, damage tier, and armor health in place.
11. With a second civilization active, bring the warriors into the arena. They
    should fight each other and hostile players. Owners and anyone outside the
    arena are protected. After death, watch the HUD count down 15 seconds before
    one replacement appears. A gear purchase during the wait should preserve it.

This is a session-only prototype with 13 choices and eight plots. The map does
not itself configure Roblox's server player limit. Selection happens inside the
game server. Saved civilization profiles, a separate lobby, server routing,
formations and abilities are future changes. Equipped player weapons attack in melee. NPC attacks
use the owner's weapon damage and armor tiers. See [prices and equipment](ECONOMY.md)
and [barracks and warriors](ARMY.md).

## Repeatable engine tests

In WSL at the repository root:

```bash
npm run check
npm run build:test-project
```

In Windows PowerShell at the repository root:

```powershell
$rojo = 'C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe'
& $rojo build default.project.json --output build\civilization-prototype.rbxlx
& $rojo build .cache\test.project.json --output build\civilization-tests.rbxlx
```

The normal place excludes test scripts. The generated test place includes test
modules and multiplayer helpers; multiplayer helpers stay idle unless a test
explicitly requests the `civilization-claims`, `warrior-combat`, `army-progression`, or
`civilization-full-server` suite. Never publish the test place.

Run the following in Studio's Assistant MCP `execute_luau` tool in the test
place's **Edit** DataModel (or through Studio's documented RunScript CLI):

```lua
-- Module tests
-- Execute the contents of tests/RunTests.luau.
-- Expected: TEST_RESULT: PASS (see current verification record for the case count)

-- Separate multiplayer run
-- Execute the contents of tests/RunMultiplayer.luau.
-- Expected: MULTIPLAYER_TEST_RESULT: PASS (see current verification record for the case count)

-- Separate army run
-- Execute the contents of tests/RunArmyMultiplayer.luau.
-- Expected: ARMY_TEST_RESULT: PASS; includes actual navigation and two 15-second waits.

-- Progression and imported models (three clients)
-- Execute tests/RunProgressionMultiplayer.luau.
-- Verifies final-hit rewards, player melee, projectiles, real respawn timing,
-- and all five imported models physically walking into the arena.

-- Eight-player run
-- Execute tests/RunFullServer.luau (or use staged=true with two initial clients).
-- The full-server suite still waits for eight real clients before gameplay checks.
```

The multiplayer run opens two clients, races their real selection requests,
checks distinct plots, throttling, and respawning, removes the winning client,
then adds a new client to reclaim the released civilization. The expanded suite
also runs controller boundary checks and actual virtual input for earning,
walk-on purchase/exit/reentry, weapon clicks, and armor prompts. Client startup has
a 45-second allowance; failed gameplay assertions remain failures.

For the command line, use your installed `RobloxStudioBeta.exe` path:

```powershell
# Replace this path with your installed Studio version directory.
$studio = "$env:LOCALAPPDATA\Roblox\Versions\<version>\RobloxStudioBeta.exe"
$repo = (Get-Location).Path
& $studio --task RunScript --localPlaceFile "$repo\build\civilization-tests.rbxlx" --runScriptFile "$repo\tests\RunTests.luau" --outputFile "$repo\build\unit-results.txt" --quitAfterExecution
& $studio --task RunScript --localPlaceFile "$repo\build\civilization-tests.rbxlx" --runScriptFile "$repo\tests\RunMultiplayer.luau" --outputFile "$repo\build\multiplayer-results.txt" --quitAfterExecution
```

References: [Studio MCP](https://create.roblox.com/docs/studio/mcp),
[client/server remotes](https://create.roblox.com/docs/scripting/events/remote).

## Verification record — October 13, 2026

- Claim tests: 8 passed in Studio; the initial missing implementation failed.
- Map tests: 5 passed in Studio; the initial missing implementation failed.
- Multiplayer: 6 passed using real Studio clients. Earlier attempts timed out
  while starting three simultaneous clients; the harness now starts two and
  adds the third after departure.
- Solo client: real selection confirmed ownership, moved the character to its
  plot, and displayed the claimed HUD. A final Britain selection and character
  reset retained Plot 01 and the HUD with the selector hidden.
- UI: the menu and HUD were visually checked in a narrow phone viewport
  (319 pixels wide, Sensor orientation, portrait simulation). The menu scrolls
  to reach its lower controls. Device simulation was stopped after testing.
- UI response fixtures: a nine-second response delay produced pending feedback,
  then timeout guidance with controls enabled. A claimed-civilization broadcast
  disabled Sparta while leaving Britain available; a successful refresh restored
  Sparta. These fixtures ran only in a temporary Play session.
- Strict `npm run check`: 2 items passed. Both documented Rojo builds passed;
  local documentation links and `git diff --check` passed.
- Review: server identity and supported IDs determine claims, claim allocation
  does not yield, generated changes stay inside the owned model, and no new
  dependencies were added. Inverting the conflict guard in an isolated copy
  caused the claim tests to fail as expected; the real source was unchanged.
- Outstanding: physical touch/controller activation. The simulated ButtonA
  input did not activate a button, so alternate-input support is not yet verified.
  See the active [OpenSpec checklist](../openspec/changes/civilization-selection-prototype/tasks.md).

These were local Studio checks for the earlier two-choice milestone. The record
below covers the expanded roster and physical tycoon milestone.

## Verification record — October 14, 2026

- Studio module suite: 54 cases passed (claims 8, economy 14, roster/themes 15,
  base map 5, moved/rotated map 4, equipment 4, physical pad geometry 4).
- Centering regression checks cover every civilization on all eight moved and
  rotated plots: Citadel corners stay inside the 84-stud foundation, perimeter
  centers coincide, respawns follow current foundations, and pad/input instances
  survive upgrades and release.
- Selection UI: the final Ming choice was reachable and active at a 319-pixel
  portrait viewport and a 705×338 landscape viewport; real selection claimed
  Ming China. Additional bottom scroll space keeps the last choices above mobile
  movement controls. Physical touch/controller hardware remains unverified.
- Both production and isolated test Rojo builds passed. Strict OpenSpec validation
  passed for all three items. Documentation links and whitespace checks passed.
- Independent developer, tester, and reviewer agents collaborated. The review
  caught and resolved a short-landscape layout collapse, overlapping placeholder
  buildings, and a debounce that blocked different upgrade pads.
- The first expanded multiplayer run passed all 12 server controller checks,
  claims, gear initialization, and read-only HUD checks, then the physical input
  helper hung waiting for the legacy PlayerModule. The test helper now uses
  actual Humanoid movement without that dependency. A second run passed the first
  100 clicks and settlement entry/standing/reentry, then exposed a test-only
  teleport/freeze replication race. Walking between all pads removed that race.
- Final multiplayer suite: **30 cases passed**, including 130 actual virtual mouse
  clicks with exactly one coin each, real Humanoid walk-on purchases, two seconds
  of standing with 75 coins available without another charge, full exit/reentry,
  separate weapon mouse and armor keyboard-prompt purchases, and upgraded tiers
  after respawn (settlement 3, weapon 2, armor 2, damage setting 15, MaxHealth 120).
  Departure/reclaim starts a new account and first-tier gear.
- Maximum-level HUD rendering passed with an explicitly temporary server-response
  fixture: all three tracks displayed MAX. This did not modify any saved data.
- Removing the owner-plot check in an isolated cloned controller made the foreign
  pad test fail; the actual controller source was unchanged. Temporary test
  scripts, modules, runtime objects, and response fixtures were removed/stopped.
- Read-only reviewer found no outstanding required source findings. The current
  [change checklist](../openspec/changes/civilization-clicker-upgrades/tasks.md)
  records the delivered implementation and verification.

No Marketplace models or scripts were imported. Player weapon attacks, saving, public
Roblox client testing, and eight-human-player load testing remain future work.

## Barracks and warrior verification — October 14, 2026

- Studio module checks passed: 69 cases. New coverage includes transformed arena
  bounds, hostile ownership and range, all 13 melee warriors at all four gear
  tiers, articulated rigs, live health-deficit preservation, armor downgrades,
  stage-two barracks, spawn clearance, and separate troop containers.
- Two-client army suite passed: 14 cases. Real server-owned warriors walked from
  Village and Citadel settlements into the arena without teleporting, exchanged
  ten-point melee hits with a one-second cooldown until death, and damaged a
  claimed enemy player only after a line-of-sight blocker was removed. Owners,
  unclaimed players, and a target outside the arena but within melee reach were
  protected. Actual character resets preserved living identity and dead-state
  replacement deadlines.
- Lifecycle tests waited through two real 15-second intervals. Live gear updates
  retained the same unit, weapon upgrades did not heal, and armor preserved
  missing health. Purchases during the wait preserved its deadline; the replacement
  used the latest damage and health tiers. Corpses disappeared and release/reclaim
  prevented stale callbacks from duplicating a new unit.
- Runtime inspection caught a competing automatic weapon grip. NPC tools now
  use one explicit attachment, while player equipment keeps its normal grip.
  The runtime lifecycle check verifies the competing grip is absent.
- The expanded two-client economy/claims suite passed 34 cases, including actual
  coin clicks and ground upgrades, production warrior gear inheritance (15 damage,
  120 MaxHealth), unchanged warrior identity after player reset, and departure cleanup.
- Removing the hostile-owner check in an isolated cloned combat module caused
  the friendly-owner assertion to fail. Production source was unchanged. Final
  module verification passed all 69 cases against fresh cloned gameplay modules.
- Both final Rojo builds passed. The production place contains 20 gameplay
  scripts/modules and no test scripts; the separate test place contains 39.
  Strict OpenSpec validation passed all four items.
- The user reported a successful manual three-player NPC playtest. This is
  separate from the automated suites above.
- Eight-client automation is not yet verified. Simultaneous startup hit a
  Roblox Direct3D device-removed error (0x887a0005). Staged startup reached three
  connected players and timed out waiting for the fourth; a subsequent retry
  timed out with one automated client while a separate manual session was open.
  A confirmed orphaned test client was removed. Temporary quality changes were
  restored to Automatic. These are startup failures, not passed gameplay cases.
- The user then chose to stop further eight-player testing and continue
  development. The reusable eight-client harness remains available for a later
  run. Do not treat its 47 planned cases or the optional eight-owner fixture as
  passing runtime evidence. New HUD layout/device checks are also outstanding.

These are local Studio checks with two clients. Public Roblox client behavior,
physical mobile/controller input, and a full eight-player load remain unverified.

## Progression, combat and imported models — October 14, 2026

- **92 module cases passed** in Studio, including settlement-level caps on all
  three upgrade tracks, actual pad creation/retirement, all 13 civilizations at
  four settlement stages, facade ownership/rebuild/release and longhouse support
  clearance, shared balance,
  five actual custom asset clones and their tier gear, and original preservation.
- **31 focused runtime cases passed with three real clients:** seven final-hit
  reward cases, eight player-melee server cases, seven real-flight projectile
  cases, six independent barracks-slot/timer cases, and three imported-model
  movement cases. All five custom rigs physically walked from walled settlements
  into the arena under server-owned Humanoid physics and retained upgraded gear.
  Respawn tests used the actual 14.5/14/13.5-second delays and waited past a
  canceled deadline after owner release.
- Initial reward LOS fixture overlapped the imported British rig's arm. Moving
  the blocker between the ray origin and the nearest target body surface retained
  the obstruction assertion; the complete runtime suite then passed.
- Building identity uses SurfaceGuis attached to existing main-hall parts, with
  separate arena/courtyard labels and 13 themes. Spartan and Mongol facade
  screenshots were inspected; Mongol orientation was verified on both faces.
- Eight-player testing remains canceled at the user's request. Published-client,
  hardware touch/controller, and persistence validation remain outside this
  milestone. Progress is still session-only.

- **43 multiplayer/native-input cases passed with two live clients and an owner
  replacement:** claim races, separate accounts, respawn/reclaim, 18 controller
  boundary cases, 130 actual coin clicks, settlement entry latches, weapon mouse
  purchase, armor keyboard prompt, and an actual player melee kill with exactly
  one attack intent and +10-coin HUD feedback. A tool whose GeneratedBy attribute
  arrived after equip was first rejected while unmarked, then correctly activated
  once marked. Gear approaches route around neighboring barracks pads, with
  pre-input balance assertions proving movement did not make a purchase.
- Seneca/Viking side-bay nameplates were reviewed and the Seneca facade inspected
  in Studio after fixing central-post occlusion. Final production and isolated
  test builds passed; both include all five templates and only the test place
  includes test harnesses. Strict OpenSpec validation passed. Temporary test and
  preview instances were removed; original placed models and templates remain.
- Follow-up: inspect the level-IV two-slot HUD and countdown layouts on device
  viewports. Server timing and slot behavior passed; those specific client layouts
  have not been visually verified.
