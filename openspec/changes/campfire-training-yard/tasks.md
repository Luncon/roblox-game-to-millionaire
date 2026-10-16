# Tasks

## 1. Exterior campfire site and construction

- [x] 1.1 Add failing world fixtures for an exterior training yard and adjacent purchase pad, saved training restoration, flat terrain and clear access across all eight plots; verify the missing layout fails in Studio with fake profiles before implementation.
- [x] 1.2 Implement the shared side-yard layout, campfire visuals, exterior training pad, terrain/scenery reservation, district clearance and perimeter opening. Preserve the purchase action, level-5/50-coin offer and trainingLevel; verify world fixtures at levels 5, 20 and 50, all civilization themes and moved/rotated maps, and document the new site in docs/WORLD.md.

## 2. Regroup and resting movement

- [x] 2.1 Add failing command and native runtime fixtures for camp arrival, bounded slow walks with pauses, fire clearance, unchanged health and interruption by Hold/Advance; verify they expose the current fixed barracks rally behavior in one solo fake-store Studio session.
- [x] 2.2 Implement server-chosen camp arrival and per-slot resting phases using existing navigation. Verify slow movement remains inside the yard, repeated Regroup preserves its cycle, blocked goals recover without teleporting, Hold stops walking and Advance restores normal speed; document command behavior in docs/ARMY.md.
- [x] 2.3 Integrate replacement and release lifecycle with resting phases; verify replacement troops return before wandering, upgrades preserve current identities/health deficits and pending deadlines, and switching or teardown clears transient work without changing saved fields or army capacity. Update the existing settlement-development runtime assertions to cover the new resting behavior.

## 3. Integrated verification

- [x] 3.1 Run npm run check, production/test Rojo builds and the complete isolated Studio module suite, including neutral-opponent regressions; record commands and results in docs/PLAYTEST.md.
- [x] 3.2 Use one solo Studio playtest to exercise the exterior purchase through native input, photograph the campfire yard, observe all three slots through multiple resting cycles and interrupt them with Hold/Advance. Check native return paths through level-20/50 side gates, owner-only protected goals, a regrouped respawn, growth and cleanup; record evidence and any unavailable runtime checks in docs/PLAYTEST.md without accessing player storage.
