# Civilization tycoon prototype

Connect Rojo to Studio and press Play. The map is generated at runtime inside
`Workspace.CivilizationPrototype`; it disappears when Play stops. Existing
Workspace objects are preserved. Large existing objects may cover the prototype.

1. Wait for your saved profiles to load, then choose an available civilization.
   Your character moves to a numbered settlement. Its themed main building shows
   your civilization and display name; the HUD shows your plot and restored progress.
2. Reset your character. You should return to the same plot with the same HUD.
3. Use one Studio Play window for ordinary progression checks. Exclusive-claim
   races require a separate focused multiplayer check: two players choosing
   Sparta must produce one owner; the other can choose Britain.
4. In that multiplayer check, disconnect the Spartan owner. A new client can
   select Sparta and reuse its plot. Close owned test windows before another run.
5. Click the gold ground button or use its prompt: each accepted activation adds
   one coin. At level one only coin and settlement pads exist. Expand to level two
   to reveal weapon, armor, and barracks upgrade pads. Each track is capped by
   the settlement level.
6. Walk onto an affordable upgrade pad, stay on it, then exit and re-enter.
   Standing should not buy multiple upgrades.
7. Reset after upgrading. Coins, all four upgrade levels, armor, the equipped
   weapon and living troop identities should remain intact.
8. Try a phone viewport and a controller. The selector scrolls; the HUD displays
   progress and provides a Change civ control. Currency and purchases still use
   ground buttons and their prompts.
9. Upgrade the settlement to stage 2. A barracks appears and deploys one melee
   warrior automatically. Watch it walk to the central arena.
10. Buy separate weapon and armor upgrades. Your living warrior should receive
    the matching civilization gear, damage tier, and armor health in place.
11. With a second civilization active, bring the warriors into the arena. They
    should fight each other and hostile players. Owners and anyone outside the
    arena are protected. Barracks I replaces a dead warrior after 15 seconds.
    A gear purchase during the wait should preserve its existing deadline.
12. Expand the settlement and gear through level 50. Each settlement level adds
    land and a lasting themed feature; completed capitals occupy 256-stud plots.
    Barracks upgrades stop at IV and reduce future replacement delays to 14.5,
    14 and 13.5 seconds.
    Barracks IV deploys one melee warrior and one ranged troop with independent
    death and replacement timers. Owner gear upgrades apply to both.
13. Use Change civ to view your saved progress and select another free civilization.
    The same plot should rebuild with that civilization's separate coins and levels.
    Selecting an occupied civilization must preserve your current settlement.
    Switch back to verify the earlier progress returns.
14. Leave and rejoin with the same account, then select the earlier civilization
    when available. Its saved settlement, gear and troop capacity should return;
    troop identities, current health and pending timers are rebuilt for the session.
    Failed loads must block selection and progression rather than start fresh.

The prototype has 13 choices, eight plots and independent saved civilization
profiles. The generated map does not configure Roblox's server player limit;
selection and switching happen inside the current server. A separate lobby,
server routing, formations and abilities remain future changes. Progress autosaves
and receives a final save attempt on departure or shutdown. Studio uses the
separate StudioDevelopment storage scope; live servers use Live. Real-storage
Studio checks require API access; the automated test place uses an injected fake
store. Equipped player weapons attack in melee. NPC attacks use the owner's
weapon damage and armor tiers. See [prices and equipment](ECONOMY.md) and
[barracks and warriors](ARMY.md).

Keep only one Studio playtest open at a time. Solo checks cover progression,
native controls, interface layout, imported NPC movement and one owner's troop
lifecycle. Multiple connected owners, claim races and hostile player/NPC combat
need their own focused multiplayer evidence; owner-interface doubles cannot
replace connected players for the shared combat authority.

## Repeatable engine tests

In WSL at the repository root:

```bash
npm run check
npm run build:test-project -- --solo
```

In Windows PowerShell at the repository root:

```powershell
$rojo = 'C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe'
& $rojo build default.project.json --output build\civilization-prototype.rbxlx
& $rojo build .cache\solo-test.project.json --output build\civilization-solo-tests.rbxlx
```

Disconnect a Rojo connection serving the normal project before opening the test
place, so its test-only bootstrap stays in place. Open the solo test place in
the existing Studio window and start ordinary **Play**.
Its Studio-only bootstrap injects a fresh in-memory store; the sole server
harness automatically runs the module suites, native repeated-pad purchases,
five imported models' physical navigation, one real owner's automatic troop
lifecycle, native civilization switching and the completed-profile HUD.
It does not call `ExecuteMultiplayerTestAsync` or create additional clients.

In the **Server** context, inspect `game:GetAttribute("SoloVerificationPhase")`
or run `tests/RunSoloWorldGrowth.luau` to poll the structured result. The complete
JSON evidence is in `ServerStorage.SoloVerificationResult.Value`; unit cases and
runtime cases are reported separately. Native input capability failures are
failures, rather than simulated signal activations. The maximum settlement
remains available for up to ten minutes of inspection. Finish inspection with:

```lua
game:SetAttribute("FinishWorldGrowthInspection", true)
```

Wait for `SOLO_TEST_RESULT` in Output, then stop Play before starting another
run. `SoloVerificationPassed` is set only after inspection and the fake-store
shutdown complete. The result explicitly lists multi-owner gameplay that the
single-client run cannot verify. Never publish either generated test place.

Before stopping Play, separate slope and ranged engine fixtures can run in the
Server context without changing the real player's profile. The slope fixture
uses one actual Humanoid; the ranged fixture uses two explicitly simulated
owners and actual NPCs/projectiles:

```lua
require(game.ServerStorage.RuntimeTests.TopographyWalk)()
require(game.ServerStorage.RuntimeTests.SoloRangedGrowth)()
```

Their two slope cases and five ranged cases are reported separately from the
solo runner's 23 cases. They do not verify connected multi-owner identity or
networking and do not launch more clients.

The imported-equipment ownership regression needs an ordinary server **Script**
in the fake-store test place, with the real player's character ready:

```lua
local player=game:GetService("Players"):GetPlayers()[1]
print(require(game.ServerStorage.RuntimeTests.ImportedEquipmentOwnership)(player))
```

It reports one separate case, creates and destroys its own nearby NPC/platform,
and checks manual server ownership after replacing imported gear and stepping
physics. Do not substitute an inspection bridge's execution context for this
server Script or repair ownership inside the test. Remove the temporary Script
after the check; it is not a production startup script.

For a behavior that specifically requires multiple real players, stop the solo
run first and generate the separate multiplayer configuration:

```bash
npm run build:test-project
```

```powershell
& $rojo build .cache\test.project.json --output build\civilization-tests.rbxlx
```

The normal place excludes test scripts. The generated test place includes test
modules and multiplayer helpers; multiplayer helpers stay idle unless a test
explicitly requests the `civilization-claims`, `warrior-combat`, `army-progression`,
`civilization-profiles`, `world-growth`, or `civilization-full-server` suite. Its bootstrap injects
an in-memory profile store; normal regression runs cannot touch production profiles.
Never publish the test place.

Use a freshly synced test place for module checks so cached modules cannot hide
source changes. Run module checks in a fresh Server Play context or through
Studio's RunScript CLI. Launch multiplayer runners from the **Edit** DataModel
after stopping Play:

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

-- Persistence and switching (two clients per independent server)
-- Execute tests/RunPersistenceMultiplayer.luau.
-- Expected: PERSISTENCE_TEST_RESULT: PASS (20 cases).
-- Covers native pads, independent profiles, periodic/final saves, a fresh
-- Studio server with the flushed fake snapshot, failed loads and retry bounds.

-- Eight-player run (deferred; canceled in the current scope)
-- Execute tests/RunFullServer.luau (or use staged=true with two initial clients).
-- The full-server suite still waits for eight real clients before gameplay checks.
```

The multiplayer run opens two clients, races their real selection requests,
checks distinct plots, throttling, and respawning, removes the winning client,
then adds a new client to reclaim the released civilization. The expanded suite
also runs controller boundary checks and actual virtual input for earning,
walk-on purchase/exit/reentry, weapon clicks, and armor prompts. Client startup has
a 45-second allowance; failed gameplay assertions remain failures.

The persistence runner starts three separate two-client servers: initial progress
and switching, restoration for matching Studio test UserIds, then locked/invalid
load isolation. A short settling gap separates server teardown and startup. This
runner verifies the injected store and session reconstruction; use the normal
production bootstrap in StudioDevelopment for a separate real-storage restart
check. Published Live-scope restoration requires its own Roblox client check.

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

## Civilization profiles and switching — October 14, 2026

- **128 module cases passed across 21 suites** in a fresh Studio Server context.
  The 19 profile-service cases include missing versus failed/invalid loads,
  independent civilization fields, session contention and expiry, stale-writer
  fencing during and after replacement ownership, ordered concurrent saves,
  changes arriving during a save, uncertain backend outcomes, bounded retries,
  departure during load, periodic saves and finalization. Schema, imported
  economy state, mutation freezes, retained switch rate limits and atomic claims
  are also covered.
- **20 persistence runtime cases passed using two real Studio clients.** The
  initial 14 cases checked private saved previews, an established level-IV
  settlement and gear, two troop slots, occupied-switch protection, independent
  progress after 55 actual coin clicks and ground purchases, character reset,
  a real-time periodic save and final flush. Four cases in a fresh Studio server
  restored the flushed snapshot for matching test UserIds. Two failure cases
  checked locked/unsupported profiles, no default writes, bounded retry traffic
  and recovery after an eligible retry.
- These automated persistence runs use the injected in-memory store and the
  test-only bootstrap. Carrying its snapshot into another Studio server verifies
  session reconstruction; it does **not** demonstrate published DataStore
  restoration or a public-client rejoin.
- Native GUI input opened the civilization switcher, scrolled to and selected
  Ming with level-II progress and 23 coins, and selected an unstarted Sparta
  profile at level I with zero coins. This exercises the actual selector controls
  rather than firing GUI signals. The final inspection also switched natively
  from Ming II/23 coins to the established Sparta IV/417 coins while retaining
  Plot 01. Native Cancel hid the selector and restored the HUD.
- Actual HUD bounds checks passed at desktop **1180 × 504.8**, compact landscape
  **634.4 × 320.8**, and tall **634.4 × 683.2** client viewports. All three MAX
  fields fit their labels, rows did not overlap, and Change civ was the only HUD
  button. Screenshots from all three viewports were viewed; the tall view showed
  restored Sparta IV, 417 coins and 2/2 troops.
- **Independent countdown layout checks passed on desktop and compact landscape.**
  After staggered troop deaths, the actual HUD helper observed warrior 6s/ranged
  9s against separate deadlines 3.016 seconds apart. Viewed desktop and compact
  screenshots later showed warrior 4s/ranged 7s. These observations complete the
  earlier level-IV HUD/countdown follow-up. The final inspection fixture passed
  separately; its checks are not added to the 20 persistence cases above.
- **Real DataStore restoration passed in StudioDevelopment** using the normal
  production bootstrap and `CivilizationProfilesV1`. Native GUI input selected
  Sparta; 25 actual coin activations bought settlement II, followed by 12 more
  coins. Stopping Play performed the final flush. A fresh Play session read back
  12 coins, settlement II and weapon/armor/barracks I. Native selection restored
  those values, Spartan tier-I equipment and one automatically deployed warrior
  using the custom template.
- The real-store run's physical-input helper timed out on activation 38 after a
  missed coin activation. Its full 55-click flow is **not** counted as passing.
  The successful 37 activations, settlement purchase, final flush and fresh-session
  restoration above are the narrower observed result. The complete 55-click
  flow passed separately against the injected fake store. This real storage check
  uses the isolated StudioDevelopment scope; published Live-scope restoration and
  a public Roblox client rejoin remain unverified.

- **43 multiplayer/native-input regression cases passed again with profiles
  enabled:** claims, respawn/reclaim, isolated accounts, controller authorization,
  actual coin clicks and ground purchases, entry latches, gear input and native
  melee rewards. This run used the isolated fake-store bootstrap.

Physical mobile/controller input, published Live-scope restoration and a public
Roblox client rejoin remain unverified. Earlier verification records above
describe the builds tested at those times; their session-only limitations do not
describe the new profile implementation.

## Expanded world and gradual settlement growth — October 14, 2026

- **144 module cases passed across 25 suites** in fresh Studio Play before the
  final facade follow-ups. The level-50 progression and saved-profile tests first
  failed against the previous implementation, then passed with the new curves.
  Settlement checks cover all 13 civilizations through every level, retained
  feature instances, moved/rotated foundations, footprint bounds, spawn and exit
  clearances, and independent 50/50/50/4 progression limits. The geometry suites
  passed again after correcting feature retention across garbage collection.
- Engine checks confirmed a 560-stud plot ring, 250-stud combat radius, five
  biome folders, dry crossings and lane reservations. Completed settlement
  fixtures contained 203–272 static BaseParts per civilization. The landscape
  contained 423 parts; an eight-capital geometry fixture contained 2,466 parts.
  The measured construction/sample-build operation took about 0.142 seconds on
  that Studio server. These are fixture measurements, not eight-player, mobile
  performance or frame-rate results.
- **147 module cases passed across all 25 suites** in the updated single-window
  solo run, including final grand-facade obstruction regressions, level-50
  save/release/reload and fractional melee/ranged lethal-hit fixtures. The
  fractional engine fixture checks nonpositive health after overkill, exactly
  10 coins for the final hit and no duplicate reward; its controlled actor
  interface does not demonstrate connected multi-owner gameplay.
- **23 runtime checks passed in one ordinary Studio Play window with one real
  client and the injected fake store.** These comprise native initial selection
  (1), advanced ground pads (6), five imported-rig movement checks (3), the real
  owner's automatic warrior lifecycle (6), native switching/Cancel (3), and the
  maximum-profile HUD (4). The inspection completion flag was set and
  `SoloVerificationPassed` became true after final fake-store shutdown.
- Stable weapon/armor pads survived repeated purchases through levels four,
  five and six. Standing retained the contact latch even with affordable next
  levels; full exit/re-entry allowed the next purchase. Settlement caps rejected
  purchases, actual mouse/key input bought gear, and the seeded 1,000-coin
  fixture ended at exactly 743 coins after the specified purchases.
- All five actual imported models physically walked from settlements at levels
  **2/25/50/25/50** into the expanded arena. Arrival times were Sparta **25.403s**,
  Britain **25.565s**, Japan **25.979s**, Seneca **29.126s**, and Maurya **26.689s**.
  Recorded entry displacements were **299.627–302.329 studs**, against a minimum
  derived from spawn and arena geometry of about **299.524 studs**. Checks retained
  server network ownership, animated walking poses and upgraded health; these
  are actual NPC movement results, not teleported arrivals.
- The one-owner fixture passed real 15-second replacement waits, gear updates
  without duplicate troops, corpse cleanup and cancellation of stale callbacks
  after release/reclaim. Native GUI controls switched to Ming II with 23 coins,
  restored Sparta level 50 with 417 coins on the same plot, then canceled back
  to the HUD. Actual HUD bounds/text checks passed at **472.8 × 560.8**, including
  all three level-50 MAX fields and the separate barracks-IV two-slot status.
- A separate **four-case ranged engine fixture passed in that same Play session**.
  Its two owners were explicitly simulated through a private actor interface;
  production connected-player validation was unchanged. Real ranged NPCs walked
  from level-25 Sparta and level-50 Britain settlements, covering **317.878** and
  **317.849 studs** in **28.650s** and **28.595s**. Actual projectile frames and
  raycast impacts dealt **11.134693877551023** and **14.4** damage. Each simulated
  owner received exactly 10 coins for one lethal hit; duplicates and nearby
  outside-arena launches were rejected. These four cases are separate from the
  base 23 and do not demonstrate connected multi-owner gameplay.
- Supplemental HUD helpers passed four checks each for early Ming II/23 coins
  on the desktop viewport and level-50 MAX on **750 × 381** iPhone 17 Pro
  landscape emulation. Desktop MAX, early Ming and compact MAX screenshots were
  viewed. Device orientation used Sensor and GUI safe insets/clipping stayed
  enabled. These supplemental checks do not change the base 23-case count.
- The expanded world and eight-capital gallery screenshot was viewed. The
  gallery contained seven static settlement fixtures and one real claimed
  plot, rather than eight players. Local inspection fog was removed and the
  lighting clock set to 14 for the overview capture. Matching Britain level
  1/25/50 captures and a ground-level dry crossing/cover view were inspected;
  see [the saved illustrations](WORLD.md#earlier-growth-illustrations). Close-up completed
  British and Spartan hall facades showed the incorporated identity panels clear
  of roofs, windows and columns. Automated obstruction regressions cover all
  thirteen civilizations. Captures required the Client tab; Server-tab captures
  returned a Studio bridge error rather than an image.
- Normal, multiplayer-test and solo-test Rojo builds completed, and strict
  OpenSpec validation passed all seven items. An independent XML review found
  duplicate server bootstraps in the test-project generator. After correction,
  rebuilt multiplayer/solo XML each contained exactly one fake server bootstrap;
  the actual solo Play context independently contained exactly one fake bootstrap.
  Production/test isolation checks passed. All solo checks used one Studio
  process and did not launch additional clients.
- Final cleanup stopped Play, removed injected fixtures and restored all 33
  gameplay scripts plus the exact normal bootstrap. Edit inspection found one
  normal startup script, no tagged test fixtures, no multiplayer launchers and
  no generated play-world leftovers. Device simulation was stopped; the single
  existing Studio window returned to its normal size. Independent review
  approved source, fixture isolation, documentation and saved scene captures.

The new single-client run does not verify connected multi-owner combat, claim
races or multiplayer networking. The historical 43-case multiplayer and 20-case
persistence results above describe the earlier build; they were not rerun
against level-50 progression. Level-50 restoration here uses fake-store session
boundaries and seeded native switches. The earlier real StudioDevelopment
restart demonstrated level-II restoration; level-50 real-store restoration,
published Live-scope/public-client behavior and hardware touch/controller input
remain unverified. No eight-client run was performed.

## Natural asymmetric topography — October 14, 2026

- **153 module cases passed across 26 suites** in fresh solo Studio Play. The
  missing-topography regression first failed against the previous map. Six new
  terrain cases verify deterministic generated triangles, asymmetric relief and
  warped biome boundaries, field height/slope limits, flat finished plots and
  full-width corridors, owned cleanup, and transformed collision geometry.
  Actual raycasts check plot/road edges, off-grid heights/normals, original
  triangle edges and internal half-wedge joins; metadata alone is insufficient.
- The complete landscape measured **1,929 static BaseParts**, including **1,472
  terrain parts**, within the 2,000-part limit. A ten-stud scan measured maximum
  heights of approximately **3.931 studs inside the arena** and **46.718 studs
  outside it**. The field design limits remain six studs and fifteen-degree
  slopes. Twenty continuous river segments and three 28-stud road-aligned dry
  crossings passed checks, alongside scenery anchors on the rendered ground.
  These counts are geometry measurements, not hardware frame-rate results.
- **All 23 base solo runtime checks passed**, and `SoloVerificationPassed`
  became true after inspection completion and the fake-store shutdown. Native
  floor-pad purchases and entry latches, five imported melee models' actual
  marches, the real owner's automatic lifecycle/15-second replacement, native
  civilization switches, and the level-50 HUD were exercised in one Play window.
- **Two separate slope traversal cases passed.** A real server-owned Humanoid
  walked 40 horizontal studs from local **(-200, -40, height 0.15)** to
  **(-200, -80, height 3.9311)**, gaining **3.6149 studs** in **3.6834s**, then
  returned downhill in **5.1842s**. Supported feet, healthy state, animated
  movement, server ownership and unchanged arena-height eligibility passed.
  The fixture did not pivot the character after spawning it.
- **Five separate ranged engine cases passed with simulated owners.** Real
  level-25 Spartan and level-50 British ranged NPCs walked **317.870** and
  **317.909 studs** in **28.480s** and **28.157s**. Real projectile frames and
  raycast impacts preserved damage of approximately **11.1347** and **14.4**;
  each accepted final hit credited exactly 10 coins once. Nearby outside-arena
  launches were rejected. The private actor-interface doubles do not verify
  connected-player identity or multiplayer networking.
- The former off-road damage-test sightline was genuinely blocked by the new
  `Desert.Scenery53.Cactus`. The final fixture explicitly verifies that blocked
  launch causes no damage or reward, then tests projectile damage over a clear
  grounded radial route at least 35 studs long. Combat protection was retained;
  no production authority change was needed for the fixture's old assumption.
- **Total runtime evidence is 30 cases: 23 base + 2 slope + 5 ranged.** One earlier
  native attempt timed out while entering the settlement pad, with no activation
  feedback and an empty touching-parts result. Its cause remains unconfirmed;
  the fresh unchanged run passed. Installing a read-only observer produced no
  saved trace, so it is not evidence of a particular contact failure. No
  production fix or relaxed purchase assertion is claimed for that timeout.
- Four saved terrain screenshots were viewed and independently reviewed: the
  overview, snowy ridge, winding river/crossings and battlefield slope. See
  [the inspected terrain](WORLD.md#inspected-terrain). They show one actual
  claimed Sparta level-50 settlement and seven unclaimed starter plots, with
  no static-capital gallery. Inspection-only settings removed local fog, set
  the clock to 14 and kept the world streamed in. The faceted native geometry
  is intentional; normal play retains its usual lighting/streaming settings.
- Final production, multiplayer-test and solo-test Rojo builds passed with the
  final source and helpers. XML isolation checks confirmed exactly one fake
  server bootstrap in each test place and the normal production bootstrap in
  the production place. Final strict OpenSpec validation passed all eight items;
  `git diff --check` passed.
- Cleanup stopped Play, removed owned fixtures and synchronized all 34
  production scripts. Final Edit checks found no tagged fixtures/probes,
  multiplayer launchers or generated play-world leftovers, and exactly one
  normal bootstrap whose source matched the repository. Topography source also
  matched exactly. The client inspection binding was removed, GUI/camera and
  original window dimensions were restored, and device simulation stopped.
  Only the one existing Studio process remained.

All new automated checks used the fake store and a single Studio Play window. Actual
connected multi-owner combat/networking, eight-client load, hardware touch or
controller input, published-client performance and Live-scope level-50 storage
restoration remain unverified; earlier results remain historical evidence.

## Imported equipment visuals — October 14, 2026

- **160 module cases passed across 28 suites** in a fresh fake-store solo Play.
  The new import suite first failed for the missing implementation. Seven new
  cases cover inert cloned geometry, removal of scripts/forces/external links
  and imported gameplay attributes, unchanged source assets, all eleven mapped
  equipment models, role-specific selection, rigid nested geometry, duplicate
  prevention and the existing damage/health curve. Player module fixtures cover
  R6/R15 body names; these are separate from the real avatar inspection below.
  The five custom melee models retain their original cosmetic instances,
  placement and appearance through all fifty upgrade levels.
- Shield fitting was followed by **23 affected module checks**, and katana hilt
  calibration by **seven affected checks**. These are reruns of existing cases,
  rather than additional unique module cases. After the ownership correction,
  the **23 affected module cases passed again**, with the same 160 unique-case
  total. The imported skins retain the
  generated authoritative Tool and stats; native procedural fallback remains
  available. See the [equipment mapping and captures](../assets/README.md#imported-equipment-visuals).
- **All 23 base solo runtime checks passed** on the fresh retry. An earlier
  attempt timed out entering a floor pad with 1,000 coins still present. Its
  initial contact was not observed, so its cause remains unconfirmed. The next
  unchanged run passed with contact events recorded by a read-only observer;
  this does not establish what caused the first failure. Production pad code
  and purchase assertions were unchanged. That run completed its gameplay
  checks, but diagnosis and photography exceeded the 600-second inspection
  wait: its overall `SoloVerificationPassed` was false from the completion
  timeout. The subsequent **final fresh run passed all 160 module cases and
  all 23 base runtime cases**, accepted the inspection finish flag, shut down
  the fake store and reported `SoloVerificationPassed=true`, phase `Passed`.
  It used the final source and saved katana grip.
- **Five ranged engine cases passed with simulated owners** on the new gear.
  The Spartan level-25 troop walked **317.8363 studs in 28.1964s**, retaining
  approximately **11.1347 damage**; the British level-50 troop walked
  **317.7273 studs in 27.5432s**, retaining **14.4 damage**. Real projectile
  flight/impact, blocked sightlines, outside-arena protection and exactly one
  10-coin final-hit credit passed. These private actor-boundary fixtures do not
  establish connected multi-owner gameplay.
- One additional real-client native mouse activation produced **one
  `Tool.Activated` and one attack intent received by the server**. This checks
  the imported player's normal tool input path, rather than a simulated signal
  or a claim of a hostile-player hit. A separate eight-rig cohort physically
  walked toward twelve-stud goals with exactly one manual weapon grip per rig;
  these are NPC fixtures in one window, not eight connected players.
- The nearby-player ownership regression reproduced a real assembly issue in
  an ordinary server Script: after imported gear replacement, the NPC's owner
  was initially the server but **automatic ownership had become true**.
  `WarriorRig.update` now explicitly retains server ownership after rebuilding
  live NPC gear. The focused regression also checks subsequent physics frames,
  the katana's rigid attachment, missing health and actual Humanoid walking.
  The same ordinary-Script regression then **passed** with a genuine nearby
  player: owner remained the server and automatic ownership remained false
  throughout the subsequent physics and walking checks. No player ownership
  override or repeated repair was injected by the test. The ownership fixture
  also passed again in the final fresh Play session.
- Seven saved equipment captures show the actual solo R15 avatar wearing
  Spartan, British, Japanese, Seneca and Egyptian gear, plus custom and
  generated troop fixtures. Equipment was applied for visual inspection while
  the fake profile remained claimed as Sparta. The Japanese katana is held at
  its calibrated hilt; the custom melee headwear is retained. See the
  [earlier equipment inspection](../assets/README.md#earlier-equipment-inspection).
- Final production, multiplayer-test and solo-test Rojo builds passed. XML
  checks matched the exact Equipment, EquipmentVisuals and WarriorRig sources,
  included eleven inert imported assets, and confirmed one normal/fake
  bootstrap as appropriate with production/test isolation. Strict OpenSpec
  validation passed all nine items; `git diff --check` passed.
- Cleanup stopped Play and restored the normal bootstrap, synchronized all
  **35 production script sources** exactly to the repository, and left exactly
  one normal server bootstrap. Edit checks found eleven inert equipment
  templates with no scripts, Tools or old joints, the saved katana hilt grip,
  no owned fixtures/launchers and no generated play world. The inspection
  camera binding had been removed and device simulation stopped; the final
  fresh run used no inspection override. The normal window dimensions were
  restored, with only the existing Studio process remaining.

**Total equipment runtime evidence is 31 cases: 23 base + 5 ranged + 1 native
tool input + 1 eight-NPC movement cohort + 1 ownership regression.** No
eight-client performance test, published-client asset-permission check or new
connected multi-owner combat verification is claimed.

## Civilization outfits and complete weapon coverage — October 14, 2026

- **169 module cases passed across 29 suites** in fresh fake-store solo Play.
  Eight outfit cases cover all thirteen exported outfits, clean body-cosmetic
  clones, R6/R15 fitting, mapped-headwear precedence, original avatar instances,
  independent template/tint/body-color restoration, later external wardrobe
  edits, late-added clothing, destroyed originals, and separate character
  snapshots. A further equipment case verifies forced same-tier application
  after late appearance loading. Existing tests retain all fifty upgrade levels,
  fractional ranged damage, one grip and the five custom melee appearances.
- The first run exposed a fixture assumption: `Rig.create` now supplies a shirt,
  so appending a second synthetic shirt made a class lookup ambiguous. The
  fixture now uses one explicitly named `FixtureShirt` and checks its exact
  template plus the unchanged original. This was a fixture correction rather
  than a clothing-preservation assertion being removed.
- Visual inspection found floating Ottoman headwear. A regression first failed
  on its actual fitted geometry, then passed after correcting and re-exporting
  the asset. It checks the visible head-piece bounding-box center relative to
  the actual head, excluding invisible handles and including mesh offsets and
  scale. Final Ottoman, Persian and Mauryan headwear corrections were included
  in the fresh 169-case rerun. Source geometry/counts remain unchanged by fitting.
- **All 23 base solo runtime checks passed** in the final fresh run, which
  completed with `SoloVerificationPassed=true` and 169 module cases. The
  earlier full run also completed successfully. Native
  pad purchases, five imported melee marches, automatic troop lifecycle,
  civilization switches and the completed-profile HUD remain covered.
- **Three real-avatar appearance cases passed** from an ordinary server Script.
  A genuine `LoadCharacterAsync` produced `CharacterAppearanceLoaded`, and the
  production hook reapplied the selected Spartan outfit. Production switches
  through Rome, Egypt and Ming then restored the exact original garment
  instances, templates, tints and body colors when cleared, preserving unrelated
  avatar items. Forced reapplication and return to Sparta restored the completed
  profile without changing coins, any upgrade track or the saved states of the
  other civilizations. This used the writable injected fake store throughout.
- **One 26-NPC movement cohort passed** with the final assets: all thirteen
  melee and all thirteen ranged variants physically walked toward twelve-stud
  goals over two seconds, with minimum displacement **11.4585 studs**. Real
  Humanoids retained rigid outfit/weapon welds, exactly one manual grip, the
  expected damage/health and explicit server ownership. These are isolated NPC
  fixtures, not connected players or a full-server performance measurement.
- **Five simulated-owner ranged engine cases passed** with the new outfits and
  weapons. Spartan level-25 and British level-50 NPCs physically marched roughly
  317 studs and used actual projectile flight/raycast impacts, retaining about
  **11.1347** and **14.4 damage**, respectively. Exactly one 10-coin lethal credit,
  cactus sightline rejection and outside-arena protection passed. Simulated
  actor boundaries do not establish connected multi-owner authority/networking.
- **One nearby-real-player ownership case passed** after Japanese imported gear
  replacement: owner stayed the server and automatic ownership stayed false,
  with one grip and rigid geometry during real walking. **One native virtual
  mouse input case** produced exactly one `Tool.Activated` and one attack intent
  at the server. No hostile-player hit is claimed from that input observation.
- Thirteen saved civilization captures were inspected, covering **39 display
  roles**: ranged on the left, melee in the center and an R15 player body on the
  right. The final Ottoman, Persian and Mauryan images were updated after their
  hat corrections. Captures: [Sparta](assets/outfits/sparta.png),
  [Britain](assets/outfits/britain.png), [Seneca](assets/outfits/seneca.png),
  [Mongols](assets/outfits/mongols.png), [Vikings](assets/outfits/vikings.png),
  [Persia](assets/outfits/persia.png), [Japan](assets/outfits/japan.png),
  [Maurya](assets/outfits/maurya.png), [Spain](assets/outfits/spain.png),
  [Egypt](assets/outfits/egypt.png), [Rome](assets/outfits/rome.png),
  [Ottomans](assets/outfits/ottomans.png) and [Ming](assets/outfits/ming.png).
  Original user-provided melee clothing and headwear remain intact. See
  [asset provenance](MARKETPLACE_ASSETS.md) for dated free-price checks and the
  [normalized outfit contract](../assets/README.md#civilization-outfits).
- Production, solo-test and standard multiplayer-test Rojo builds passed,
  including **13 outfit models and 19 equipment models** with inert visual
  whitelists. Isolation checks verified the exact normal production bootstrap
  and no production test folders. Strict OpenSpec validation passed all ten
  items; `git diff --check` passed.
- Final cleanup stopped Play and restored the normal bootstrap. Edit inspection
  matched all **36 production script sources** exactly to the repository and
  confirmed thirteen inert outfit models and nineteen inert equipment models.
  No owned playtest fixtures, staging imports, galleries or previews remained.
  The normal window dimensions were restored, and only the existing Studio
  process remained open.

**Total outfit runtime evidence is 34 cases: 23 base + 3 appearance + 1
26-NPC movement cohort + 5 ranged + 1 ownership + 1 native tool input.** Reruns
are not additional unique cases. One real R15 avatar body was tested; other avatar
proportions, hardware/mobile input, published asset permissions and connected
multiplayer behavior remain unverified.

### Rounded troop head follow-up — October 14, 2026

- Reproduced the missing head mesh before the fix: the new regression failed
  with `Rectangular troop head: sparta / ranged`. The five custom melee templates
  already had Head meshes (scale 1.25, Britain 1.3) and remain unchanged.
- Generated troops now use the built-in Head mesh at 1.25 scale and built-in
  face texture. All 26 melee/ranged variants retain their head mesh/face through
  level-50 gear upgrades. The new fixture initially exposed shared cleanup-array
  indexing in the older melee test; a dedicated melee-rig table corrected it.
- Fresh module run: **170 cases across 29 suites passed**. A separate actual
  26-NPC movement cohort passed: every rig moved at least **11.4585 studs** in
  about two seconds, keeping rigid cosmetics, one manual weapon grip, unchanged
  stats and explicit server ownership.
- Native Studio views confirm rounded faces and retained hats:
  [Vikings](assets/outfits/vikings-rounded-heads.png),
  [Maurya](assets/outfits/maurya-rounded-heads.png), and
  [Ottomans](assets/outfits/ottomans-rounded-heads.png).
- The broader solo harness did **not** complete in this follow-up. After its
  initial native selection check, AdvancedPads timed out at `settlement six
  coins=955` during native contact checks. Floor-pad timeouts were recorded
  before this change; this run does not establish their cause. The earlier
  169/23 full solo pass above remains earlier evidence, not a claim for this run.
- Production build, strict OpenSpec validation and diff checks passed. Play was
  stopped; all 36 managed sources matched the repository, normal startup was
  restored, zero owned fixtures remained, and only one Studio window stayed open.

### Civilization troop skin and warrior-face follow-up — October 14, 2026

- Reproduced missing behavior before implementation: the new suite failed with
  `Civilization troop skin and warrior faces are not implemented`.
- Fresh focused single-window Play used the injected fake solo store, with the
  broader floor-pad harness removed before Play. **173 module cases across 30
  suites passed**. Three new cases cover all thirteen civilizations and both
  troop classes at spawn/levels 25/50; consistent body colors; one warrior Front
  face; same-tier appearance repair without healing; preserved other-side decals;
  unchanged source models, head meshes, clothes and player avatar behavior.
- The actual 26-NPC movement cohort passed with a minimum **11.4067 studs** in
  about two seconds, rigid cosmetics, one manual grip and explicit server
  ownership. Workspace inspection separately verified the configured body tint
  and exactly one warrior face on all 26 gallery troops after engine updates.
- Native views checked the visibly different NPC palettes and angry expression
  against player avatars: [Britain](assets/outfits/britain-warrior-palette.png),
  [Seneca](assets/outfits/seneca-warrior-palette.png), and
  [Maurya](assets/outfits/maurya-warrior-palette.png). Helmets, masks and clothing
  remain in place. Skin painted into opaque clothing textures remains original.
- Production, solo and standard test builds passed. Strict OpenSpec validation
  and diff checks passed. Cleanup restored normal startup and all **37 managed
  sources** exactly; Edit retained thirteen outfits/nineteen equipment models,
  zero owned fixtures and one Studio window. This focused run does not reverify
  native floor-pad contact, multiplayer or published asset loading.
