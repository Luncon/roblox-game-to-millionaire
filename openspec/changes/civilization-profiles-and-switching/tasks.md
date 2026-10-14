# Tasks

## 1. Validated profile persistence

- [x] 1.1 Add versioned per-civilization profile validation and Economy imports/mutation guards; verify malformed, copied, capped and monotonic revision cases in Studio specs.
- [x] 1.2 Add exclusive session acquisition, serialized saves/retries and finalization; verify nil versus failed loads, owner fencing, expiry, uncertain writes, dirty revisions and late departure through a fake store in Studio.
- [x] 1.3 Document schema, autosave/lease timing, failure states and Studio/live separation; check documentation against delivered configuration and official Roblox guidance.

## 2. Civilizations and server lifecycle

- [x] 2.1 Add atomic plot-preserving civilization switching; verify occupied/idempotent/invalid choices preserve the current claim in registry specs.
- [x] 2.2 Integrate load gating, restored Economy/map/equipment/army, private profile previews, autosave, departure and shutdown; verify restored multi-civilization states and no stale actors in a small multiplayer suite.
- [x] 2.3 Document switching, continuation and save-status behavior; verify a leave/rejoin restoration with isolated test state and separately record real DataStore evidence.

## 3. Selector and HUD

- [x] 3.1 Add saved/new/current previews, change/cancel controls, retry feedback and accurate save notices; verify native selection and switching through a running client without adding currency/purchase GUI controls.
- [x] 3.2 Inspect level-IV progression, two troop slots and independent countdowns in desktop and compact viewports; verify actual replicated text bounds and screenshots, and close the previous HUD follow-up only after observation.
- [x] 3.3 Update setup/playtest documentation for persistent Studio testing and delivered UI; verify the documented test commands and record device/public-client limitations accurately.

## 4. Integration verification

- [x] 4.1 Run module, persistence/concurrency and small multiplayer/native regressions, resolve independent review findings, and record exact evidence without eight-player claims.
- [x] 4.2 Build production and isolated test places, validate strict OpenSpec, and verify fake-store/bootstrap/test content is excluded from production and temporary Studio changes are cleaned.

## Verification

128 Studio module cases across 21 suites, 20 two-client persistence cases and
43 current multiplayer/native-input regressions passed. A separate inspection
verified native saved-civilization switching/cancel, actual level-IV HUD bounds
and independently staggered troop countdowns in desktop and compact viewports;
a tall viewport was also inspected. Normal production startup using Roblox
StudioDevelopment storage restored Sparta with 12 coins, settlement II, its
equipment and automatic warrior after stopping and restarting Play.
Both Rojo builds, production/test isolation, strict OpenSpec validation and
independent review passed; temporary Studio test content was cleaned.
See docs/PLAYTEST.md for exact evidence and the partial real-store input helper.
Published Live/public-client rejoin and physical mobile/controller tests remain
unverified. Eight-player testing remains canceled by the user.
