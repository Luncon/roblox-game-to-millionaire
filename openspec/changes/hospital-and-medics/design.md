# Design

## Context

See proposal.md for the requested outcome and confirmed slot/command decisions. Current `WarriorService.slotDefinitions` has independent `warrior`, `ranged` and optional `camp` records; each already owns death handling, navigation, its rig and a pending respawn deadline. Its camp class selection is resolved at next spawn. Medic deployment should extend that lifecycle rather than create a competing army manager.

`CombatService` currently admits only player/warrior/ranged actors. `CombatRules.canDamage` intentionally requires hostility and battlefield membership, so it cannot be reused to validate friendly healing. `CombatEncounter` and `WeaponSkillService` dispatch non-ranged NPCs to offensive melee behavior and must explicitly exclude the new support class. Existing ranged retreat constants and navigation provide bounded safe movement, while Hold already permits in-range attacks.

`ArmyRest` brings Regroup troops to a 28-by-28 campfire yard at plot-local (-148,-12), then alternates safe walks and pauses. It contains no healing. `TrainingCamp.contains` checks horizontal bounds only, so recovery needs a physical-height guard as well. Hospital-enabled healing must not depend on the army still having a living medic.

`SettlementDevelopment.persistentFields` and `ProfileData` currently carry fifteen scalars. Version-one keys/scopes and missing-only defaults are established contracts. `SettlementSites`/Topography reserve exterior building sites before landscape generation; later district walls require explicit access openings. The landscape limit is 2,000 static BaseParts and the settlement limit is 400.

## Goals / Non-Goals

**Goals:** add one independent, targetable support unit; make Advance prioritize wounded patients, fall back behind healthy fighters and retreat from danger; retain stationary Hold attacks and support; add physical-yard recovery gated by a saved hospital; keep authority, existing progression and unit timers intact.

**Non-goals:** replacing the camp reinforcement choice, changing fighter damage or skill timing, healing players/foreign owners, saved troop health, revival, hospital tiers, paid consumables or new asset dependencies. Existing pending player-animation and multiplayer acceptance is not established by this feature's builds.

## Decisions

### 1. One saved building purchase and an independent slot

Add `hospital` to the canonical building/offer catalog with `hospitalLevel` integer 0–1, settlement 10, Training Yard I and a 200-coin first purchase. Add its field to the canonical persistent list, ProfileData default/copy validation, Economy state/snapshot copies, profile publication, HUD data and existing fixtures. Default only an absent value to zero; reject invalid supplied values and unmet hospital prerequisites. Preserve the original fifteen scalars, `schemaVersion=1`, `CivilizationProfilesV1` and StudioDevelopment/Live scope selection.

Add a `medic` slot only when hospitalLevel is one. Maximum capacity becomes barracks capacity plus armyCampLevel plus hospitalLevel. `extraTroopClass` remains warrior/ranged and Army Camp still changes class only at next spawn. Hospital ownership alone creates its slot, including legacy settlement-10+ states without an army camp. This follows the user's explicit hospital-origin decision; replacing a camp fighter with a medic is rejected.

Use the existing owned-slot container and death/disposal guards, with per-slot spawn site and future-delay resolution. Fighters keep barracks delays; the medic uses a fixed hospital delay of 15 seconds. Hospital spawn selection is a grounded clear point outside its entrance. A purchase never re-times existing waits, replaces living fighters or heals them. Existing armor health applies to current/replacement medics while preserving their health deficit. Weapon levels do not scale healing or give medics attacks.

Publish MedicCount, MedicRespawnAt and HospitalLevel separately; total ArmyCount includes support while WarriorCount/RangedCount do not. Keep barracks timing labels scoped to fighters and show the medic's hospital timer. No new medical client RemoteEvent is needed: clients request the hospital purchase and existing army commands only.

### 2. A compact rear site with a permanent access route

Reserve a candidate plot-local hospital center at (0,0,146), a building footprint up to 20 by 16 studs, its entrance facing toward the settlement, and a purchase/standing area centered near (24,0,140). The final foundation ends at local +Z 128; +Z is behind each settlement, away from the arena. Connect the entrance to the existing rear settlement circulation with an approximately eight-stud-clear route and an opening through later rear perimeter walls. Use one shared site/configuration for geometry, controls, spawning, reservations and scenery exclusion.

A planning calculation using WorldConfig's 560-stud plot radius and 1,600-stud world found all eight proposed building reservations inside world bounds. The north plot is constrained by the entry reservation beginning at world Z 720; the proposed hospital reservation ends at 718. This is a bounding calculation, not native geometry acceptance. Its control standing area, approach, native water/crossings and all civilization roof/footing extents still require geometry fixtures before finalizing coordinates. Small clearance adjustments must preserve the rear location and existing world size.

Reserve flat connected terrain before Topography builds its triangles, exclude scenery and district lots from the corridor, and ground footings/controls with the existing sampler. Use existing civilization building style plus an original ward/supply appearance and a readable facade sign. Keep the hospital and pad fixed through level 50, retain the original map/entry/farm access, and verify both geometry budgets rather than increasing them. No global Terrain edits or imported hospital model are required.

### 3. A recognizable support rig with explicit offensive exclusions

Extend the shared troop creation/update path to support a procedural R6 medic using the civilization's existing outfit, skin-tone defaults and a recognizable bandage satchel. Do not reuse custom melee source models or attach a faction's offensive weapon to it. Retain existing source joint/wardrobe preservation and server network ownership. Add ready/throw/retreat poses on the server NPC animation path.

Allow CombatService to register `medic` as an owned targetable actor. Preserve ordinary hostility/protection and final-hit rewards when an enemy kills it. Explicitly reject medic sources in ordinary damage, projectile-damage and weapon-skill paths; bypass CombatEncounter's offensive planning for this class. Enemy targeting can select medics, but a non-attacking medic must not be classified as a melee pressure source merely because it is not ranged.

### 4. Backline plans reuse navigation without issuing fighter orders

Add a bounded support planner/controller called from the existing army think/update flow for the medic slot. Use existing actor snapshots, hostility checks, navigator and Motion conventions; do not retarget fighters or create formations.

Under Advance, first heal a visible current owned patient already within 45 studs, using the existing health-priority rules. Stay within healing reach even when fresh replacements are far behind. Otherwise prioritize wounded owned patients with a reachable safe healing position: consider eight directions approximately 28 studs from the patient, require clear sight and grounded arena-safe endpoints, reject endpoints within 18 studs of a hostile and straight approach legs passing within 12 studs, and choose the shortest valid approach. Re-evaluate current patient lives/health every think; never retain a dead, full-health or obsolete life.

Only when no patient can be helped, anchor on the centroid of living current owned non-medic troops. Determine forward from their nearest relevant hostile direction, falling back to the owner's arena approach direction. Prefer a position 12 studs behind that front, then ground/check candidate routes and separation. Choose a safe owner-side support rally when fighters are absent. Patient seeking may move alongside the fighters; it must not pursue enemies or enter another settlement. Native navigation and the existing threat-first retreat still guard actual travel.

Threat handling precedes patient selection. Within the existing 12-stud trigger, cancel an unlaunched cast and score safe retreat candidates away from threats, aiming for 18-stud separation. Reuse bounded retreat distance/time and route checks so the medic cannot kite indefinitely, leave the valid battlefield route or teleport when blocked. After a bounded burst it re-evaluates support rather than fleeing forever. Retreatment does not alter heal cooldowns or fighter orders. Already launched bandages keep their independent guarded flight unless a command/lifecycle change cancels them.

Under Hold, stop navigation and retain the held position. Fighters keep the current in-range contact logic; medics throw only to valid in-range patients and do not reposition or flee. This gives the user's explicit Hold behavior priority over general Advance avoidance.

Under Regroup, cancel unlaunched and in-flight medical work, route through the existing training entry and reuse ArmyRest. Give the medic a distinct arrival index, proposed 6 alongside warrior 1, ranged 2 and camp 8, to preserve fire clearance and four independent rest states. Pause field casts during Regroup; all eligible troops can use yard recovery. Advance/Hold resumes support without resetting cooldowns.

### 5. Server-only healing with actual bandage flights

Add a narrow medical validation/application path shared by bandages and yard recovery. It must validate an active writable owner/claim, current civilization and plot, a registered owned live NPC patient and the original Humanoid life. Exclude players, neutral units, passive tending workers, enemies, self-bandaging and full-health targets. Apply only the missing health up to current MaxHealth; emit a distinct healing indicator, not LastHitAt, damage callbacks, skill procs or currency rewards. There is no client healing request or client-provided health, patient or amount.

For bandages, require a valid living medic source and hospital ownership at launch and contact, plus current range and visibility. Prioritize the lowest health fraction, then greatest deficit, distance and stable slot identity among visible, currently registered patient lives. Exclude blocked or obsolete candidates before ranking so they cannot starve a valid wounded troop. Snapshot the selected patient life and use modest server-velocity lead for a visible, slightly arced throw. Provisional tuning is 12 HP, 45 studs, three seconds between launches, roughly 60 studs/second and a one-second flight lifetime. One pending flight per medic bounds medical projectiles to at most eight for the eight-player roster.

Advance flights with bounded swept contact checks. Obstructions stop the flight; misses expire. Never redirect a bandage onto another patient or a replacement life. Duplicate resolutions consume the flight once. Range/line-of-sight/source authority and health bounds are rechecked at contact even if the target or medic moved. Friendly healing can occur along owned approach routes; do not misuse hostile-only canDamage as a healing test. Existing hostile combat boundaries remain unchanged.

A launched flight spends its cooldown even on a miss. Store medic cooldown deadlines by owner/medic slot within the current server, preserving them through purchases, switches and replacements; do not save them across servers. Regroup, departure, death, switch, lease loss or teardown cancels invalid pending work. Remove only generated projectile/effect instances and never imported models.

### 6. Yard healing is physical, independent and unbanked

Track a small transient recovery record per living owned troop/Humanoid. Require active writable hospital and Training Yard ownership, horizontal inclusion within the current plot-local yard with a small interior margin, and height within the real camp/root-clearance band. Check current world transforms; an order or distant rally goal alone cannot grant healing.

Eligibility requires two uninterrupted seconds inside and without recent damage. Existing LastHitAt plus a recorded health decrease can detect combat/external damage without treating heals as hits. At eligibility, allow the first five-health tick, then schedule at most one per second from current time. A stalled frame never pays missed intervals. Leaving, damage, lost authority, full health or lifecycle teardown clears eligibility/deadlines; no full, offline or inactive time is banked. Regroup's normal slow wander remains eligible while actually inside; Hold inside is also eligible. Returning after leaving requires a fresh wait.

Use the same clamped health application for simultaneous bandage/recovery contacts. The medic itself can recover in the yard, and fighter recovery remains enabled while the medic is dead. No live health, medical target, order, trajectory, cooldown or recovery clock enters saved profiles.

### 7. Verification extends the established isolated harness

Add deterministic offer/profile/healing/planner/timer fixtures to the Luau runner using explicit fake actors/clocks/stores. Native fixtures cover hospital construction, clear rear access, medic appearance/throws, actual range/LOS/sweeps, enemies damaging medics, four-slot counts, independent respawns, Hold attacks plus healing and four-slot camp arrival/recovery. Extend the test-project generator with a dedicated medical solo mode while preserving existing local 3,000-coin manual testing and all regression modes.

Use one Studio playtest at a time. Perform solo native checks first; use a focused two-client session only to establish owner/civilization isolation and replicated bandage/health behavior. Never run automated profile fixtures against player data. Record exact evidence and inaccessible runtime checks in docs/PLAYTEST.md; build/spec success is not healing/AI acceptance. Real StudioDevelopment storage restoration is a separate manual verification, not part of fake-store acceptance.

## Risks / Trade-offs

- [A healer removes meaningful attrition] → initial 12-HP/3s bandages and 5-HP/s home recovery are explicit prototype defaults; measure single/multi-unit fights before changing rates.
- [A fourth slot resets or duplicates existing deployments] → reuse slot/life identity, independent source/delay and idempotent construction; test living and pending states.
- [Support classified as melee silently attacks or pressures enemies] → explicit capability/class guards in offensive dispatch and enemy pressure logic; adversarial direct-call fixtures.
- [Rear hospital overlaps late walls, entry or native relief] → shared reservations, level/roster/plot geometry matrix, transformed-world fixtures and fixed budgets before native path acceptance.
- [Healing is transferred to a new life or another civilization] → owner/claim, rig/Humanoid and authority revalidation at each contact/tick with exactly-once tokens.
- [Hold accidentally becomes a chase order] → dedicated stationary support planning with existing fighter contact tests; retreat is Advance-only.
- [A downgrade drops saved hospital purchases] → roll back only to hospital-field-aware profile writers with medical deployment/healing disabled.

## Migration Plan

1. Land the sixteen-field missing-only hospital extension and guarded purchase with legacy/fake-store round trips.
2. Add reserved hospital geometry, controls and spawn/access helpers; verify placement before live AI.
3. Add one inert targetable medic with independent slot lifecycle and accurate UI counts; prove no offensive dispatch and no fighter/timer changes.
4. Add server-only bandage support, backline planning and Hold/Regroup behavior in small independently verified slices.
5. Add yard recovery clocks and bounded presentation independently of medic availability.
6. Complete isolated native geometry, commands, healing, respawns and two-owner checks; update implemented docs only with actual evidence.
7. For rollback, disable medical behavior/availability while retaining hospitalLevel in all readers/writers and preserving existing profile keys and progress. Never silently clear a stored hospital or revert to a writer that discards the field.
