# Tasks

Initial implementation and isolated fake-store/native verification are complete except separate published-storage restoration. The follow-up acceptance pass checks visible patient selection, compact four-slot presentation and sustained combat. Use fake stores for automated checks and keep one Studio playtest open at a time. Prototype tuning is recorded in proposal.md/design.md; hospital ownership adds a fourth independent slot, never a new Army Camp class choice.

## 1. Hospital progression and saved ownership

- [x] 1.1 Add hospitalLevel to the canonical persistent fields, ProfileData and every Economy/profile publication/copy path; prove sixteen-field independent civilization round trips, preservation of the original fifteen values, missing-only zero defaults, malformed/prerequisite rejection and unchanged version-one keys using injected fake stores. Document migration and field-aware rollback in docs/PROFILES.md.
- [x] 1.2 Add the settlement-10, Training Yard I, 200-coin hospital offer/purchase to the existing guarded development flow; verify exact charge, no Army Camp dependency, absent locked/completed offers, duplicate/foreign/distant/non-writable rejection and no health/timer mutation. Update docs/ECONOMY.md with eligibility and capacity effects.

## 2. Rear hospital and physical access

- [x] 2.1 Add shared hospital site/footprint/entrance/control/spawn definitions and terrain/scenery/district access reservations; verify all eight plots, level-five through level-fifty growth and moved/rotated worlds clear the final foundation, entry, farms, arena and neighbors while retaining landscape <=2000 and settlement <=400 BaseParts. Keep candidate coordinates adjustable only within the rear-site contract.
- [x] 2.2 Add civilization-themed hospital geometry, facade explanation and the next eligible physical purchase control with grounded supports; verify all thirteen civilization variants and exact native single-purchase behavior with fake profiles. Document the rear site and accessible route in docs/WORLD.md.
- [x] 2.3 Add the rear wall opening and safe hospital deployment exit; run a solo native movement/path check at early and perimeter stages to demonstrate a grounded rig can leave the hospital, reach the army and return to the training yard without crossing blocked geometry. Record concrete results or inaccessible checks in docs/PLAYTEST.md.

## 3. Independent support slot and targetable rig

- [x] 3.1 Add the medic rig/update/appearance and class registration paths with current owner armor health, original bandage equipment and server ownership; verify template/outfit immutability, preserved health deficit and direct-call rejection from ordinary/projectile/weapon-skill damage paths while enemy attacks and exactly-once kill rewards still work. Document role/gear behavior in docs/ARMY.md.
- [x] 3.2 Extend owned slot definitions, hospital spawning, death/disposal and per-slot delay logic with one independent 15-second medic replacement; verify capacity with/without Army Camp, no duplicate deployment, unchanged living fighter identities, independent deaths, purchases during pending waits, current-order replacements and cleanup on owner/civilization/world changes.
- [x] 3.3 Publish HospitalLevel/MedicCount/MedicRespawnAt and accurate total counts/status; verify medics are excluded from melee/ranged counts, camp choices remain warrior/ranged and its next-spawn semantics remain unchanged. In a solo fake-store run, observe four living troops and only the medic's countdown after its death; update docs/ARMY.md and docs/PLAYTEST.md.

## 4. Authoritative bandage healing

- [x] 4.1 Add server-only medical eligibility and clamped health application; verify same-owner/current-civilization registered NPC patients, writable authority, source/target life identity, no enemies/players/passive workers/self-bandaging, no revival/overheal and no currency or attack procs. Include simultaneous yard/bandage bounds fixtures before integrating either caller.
- [x] 4.2 Add lowest-health-fraction patient selection and one bounded visible arced bandage per medic with 12-HP contact, 45-stud range, three-second launch cooldown, swept obstruction checks and expiry; prove exactly-once contacts, stable target ties, moving/missed/blocked/replaced patients and cancellation/cooldown preservation with fake clocks and native geometry. Document initial tuning and cleanup in docs/ARMY.md; capture an actual throw/heal in the isolated solo harness.

## 5. Backline tactics and army orders

- [x] 5.1 Add Advance support positioning behind living fighters, a no-fighters support rally and threat-first bounded retreat using existing navigation/route checks; verify approximately 12-stud backline positioning, 12/18-stud avoidance thresholds, obstacle/arena bounds, no infinite kiting, no enemy pursuit and no interference with fighter target reservations. Use native solo footage/health checks to demonstrate the medic avoids a closing opponent.
- [x] 5.2 Integrate stationary Hold healing, existing in-range fighter attacks and Regroup cancellation/return with a distinct fourth camp arrival/rest route; verify Hold never moves/chases, nearby fighters attack while the medic heals, Regroup cancels pending flights, safe four-slot camp wandering and command changes preserve all cooldowns/deadlines. Document the command table in docs/ARMY.md and record a native mixed attack/heal Hold case.

## 6. Training-yard recovery

- [x] 6.1 Add transient per-life yard eligibility and recovery clocks using actual plot-local bounds/height, Hospital I plus Training Yard I, a two-second undamaged wait and five-health ticks at most once per second; verify boundary crossing, vertical exclusion, full health, external damage, Hold/Regroup, absent/dead medic, no offline/inactive/full/stalled catch-up and reset on authority/lifecycle changes. Add fake-clock fixtures and update docs/ARMY.md with observed behavior.
- [x] 6.2 Add hospital/yard explanation and recovering/full-health presentation without rebuilding geometry every tick; verify a wounded army including its medic visibly heals to current MaxHealth, stops when leaving, does not revive dead troops and keeps ordinary camp movement and pending replacements intact in one isolated solo run. Record exact UI/health evidence in docs/PLAYTEST.md.

## 7. Integration and acceptance evidence

- [x] 7.1 Extend the Luau fixture runner and test-project generator with a dedicated solo medical mode using injected FakeProfileStore; run the existing skill/combat/economy/profile/camp/geometry regressions, new medical fixtures, npm run check and production/test Rojo builds. Verify mode guards and existing 3,000-coin local-playtest mode remain intact; document runnable commands in docs/SETUP.md.
- [x] 7.2 Run one isolated solo Studio acceptance session for hospital purchase/access, four-slot deployment and separate respawns, visible bandage hits/misses, threat retreat, Hold attacks plus heals, Regroup and yard recovery through full health and civilization switching. Record measured health/cooldowns, geometry budgets, cleanup and unavailable checks without treating build/spec validation as gameplay acceptance.
- [x] 7.3 After closing solo Play, run one focused two-owner Studio session for ownership/civilization isolation, replicated bandage/health presentation, foreign-yard rejection, life replacement and lease-loss cancellation; close owned test windows and record results separately from solo evidence.
- [ ] 7.4 Separately verify real hospital restoration in an authorized published test experience using StudioDevelopment storage when available; keep automated fixtures fake-store-only and record actual restoration or the remaining verification boundary in docs/PLAYTEST.md without claiming fake-store checks prove real storage.
- [x] 7.5 Prevent blocked or obsolete critically wounded candidates from starving visible valid patients; retain health-priority selection and prove the regression before the fix, then verify actual obstacle/health behavior in solo Studio.
- [x] 7.6 Verify four-slot army and hospital-origin/countdown presentation at desktop and compact viewport sizes; fix clipped/overlapping status and command controls, and capture actual native UI bounds and screenshots.
- [x] 7.7 Measure sustained single/multiple-opponent combat with a medic, including healing influence, threat response, damageability and independent replacement; review the complete feature and record evidence plus remaining boundaries without changing initial healing rates merely to make checks pass.
- [x] 7.8 Make Advance prioritize visible wounded patients and safe approaches, with backline/rally only as fallback; reproduce the distant healthy replacement regression, verify native death/respawn while a wounded fighter remains at the front, and preserve threat-first retreat, Hold, Regroup, authority and cooldown rules.

## Workflow follow-up

- Review the complete medical implementation and its evidence before syncing/archiving its implemented capabilities. Keep unverified acceptance tasks unchecked.
- Measure healing influence in single/multi-unit fights before introducing hospital tiers or changing the initial tuning. Do not expand this change into player healing, revival or mounts.
