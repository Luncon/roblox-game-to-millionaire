# Civilization selection prototype

Connect Rojo to Studio and press Play. The map is generated at runtime inside
`Workspace.CivilizationPrototype`; it disappears when Play stops. Existing
Workspace objects are preserved. Large existing objects may cover the prototype.

1. Choose Sparta or Britain. Your character moves to a numbered settlement,
   its sign shows your civilization and display name, and a HUD shows your plot.
2. Reset your character. You should return to the same plot with the same HUD.
3. Start a Studio server with two clients. Have both choose Sparta: only one
   should succeed; the other can choose Britain on a different plot.
4. Disconnect the Spartan owner. A new client can select Sparta and reuse its plot.
5. Try a phone viewport and a controller. Choices use button activation for
   mouse, touch, and gamepad. Short screens can scroll the selection panel.

This is a session-only prototype. Eight plots are present, but only two players
can own settlements because only two civilizations are implemented. The map
does not itself configure Roblox's server player limit. Selection currently
happens inside the game server. Saved civilization profiles, a separate lobby,
server routing, upgrades, armies, formations, and combat are future changes.

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
explicitly requests the `civilization-claims` suite. Never publish the test place.

Run the following in Studio's Assistant MCP `execute_luau` tool in the test
place's **Edit** DataModel (or through Studio's documented RunScript CLI):

```lua
-- Module tests
-- Execute the contents of tests/RunTests.luau.
-- Expected: TEST_RESULT: PASS (13 cases)

-- Separate multiplayer run
-- Execute the contents of tests/RunMultiplayer.luau.
-- Expected: MULTIPLAYER_TEST_RESULT: PASS (6 cases)
```

The multiplayer run opens two clients, races their real selection requests,
checks distinct plots, throttling, and respawning, removes the winning client,
then adds a new client to reclaim the released civilization. Client startup has
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

These are local Studio checks. Published Roblox client testing and all eight
players owning different civilizations need later milestones.
