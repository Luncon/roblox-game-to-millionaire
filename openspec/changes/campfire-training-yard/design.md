# Design

## Context

See proposal.md for the requested outcome and the user's clarification to keep wandering inside the training yard. SettlementInfrastructure currently draws practice posts at SettlementSites.training=(0,0,25). PadCatalog places training at (0,34). BattlefieldMap.getArmyRally returns fixed barracks-side offsets, and WarriorService's regroup branch repeatedly navigates to those offsets. The navigator already supports cancellation and avoids stale asynchronous paths.

Topography reserves the final 256-stud plot and rural sites before generating terrain. District growth has additional reserved lots, and level-20+ perimeter walls currently seal the entire west/east sides. The working tree contains the completed neutral-opponent implementation; preserve it.

## Goals / Non-Goals

Goals: one shared geometry definition for the side yard, pad, entry corridor and resting goals; natural server-owned troop movement; safe interruption by existing commands; no saved-data changes.

Non-goals: a general patrol system, user-selected destinations, moving the yard at each growth level, modifying neutral opponents or adding troop capacity or training effects.

## Decisions

1. Use a fixed exterior yard on the plot's left side. Proposed local coordinates are center (-148,0,-12), a 28-by-28-stud yard and a purchase pad at (-148,0,14). This leaves the yard and pad beyond the final half-width of 128 studs, avoids the farm sites and radial battlefield road, and keeps the location stable across upgrades. Alternatives: putting it inside the plot fails the exterior-site request; moving it outward with each upgrade adds unnecessary target and geometry churn. Geometry tests must validate all eight plots before accepting these coordinates; minor clearance adjustments must preserve the same exterior layout.

2. Put the site, yard bounds, pad position, approach clearance and ring positions in the shared settlement layout configuration. PadCatalog consumes that definition instead of duplicating coordinates. Reserve the exterior site and forecourt in Topography/scenery generation, and exclude a westward approach at local z=-12 from district placement. Split the west perimeter wall around a walkable side opening at that approach once walls appear. Keep the existing arena exit usable. Ground the exterior camp and pad using the same flat reservation and height conventions as rural infrastructure; do not reuse the elevated interior practice-yard height.

3. Keep the existing TrainingYard model identity, training action, trainingLevel field, price, unlock and checkpoint predicates. Rebuild its visual as an original stone ring, crossed logs, a warm flame/light, small peripheral seating and a readable training label. Native effects or procedural parts are sufficient; use inert decoration with no damage callbacks. Keep walking space around the flame clear and make decorative pieces nonblocking. Existing civilization colors can accent the site. Preserve the current infrastructure cache so farm-reserve ticks do not rebuild it.

4. Change getArmyRally to return distinct camp arrival positions for warrior, ranged and reinforcement slots, derived from the current plot frame. Add a small shared ring layout with eight safe points approximately nine studs from the fire. Consecutive adjacent points keep walking segments clear of the fire; benches stay outside this route. Reuse WarriorNavigator for the return to a shared clear entrance and a guarded native MoveTo leg once inside the bounded yard. Studio exposed NoPath for several interior ring destinations despite clear collision space; short physical walks inside the yard avoid depending on those navmesh destinations. Both the current position and selected goal must be within the reserved yard before using direct movement. Verify actual rig footprints stay within the yard, including translated/rotated fixture worlds.

5. Give each owned slot transient regroup phases: returning, walking and pausing. Return at the existing normal speed of 12; after arrival, walk at a proposed speed of 5 and pause for staggered 2–5-second intervals. The server selects the next adjacent ring point and retains that goal until arrival or a bounded retry deadline. Never generate a new destination every think tick. Blocked goals retry or advance to another safe adjacent point without teleporting. Distinct slot starts and pause offsets reduce crowding. Keep WarriorState=Regrouped after initial arrival so existing observers retain a recognizable resting state.

6. Clear resting goals and restore normal speed when Hold or Advance changes the order; Hold captures the current position and stops navigation, while Advance resumes existing targeting. Idempotent Regroup calls preserve an active rest cycle. Replacement slots start in the returning phase when their owner's current order is Regroup. Equipment updates, civilization-specific outfits, health deficits, slot identities and respawn deadlines remain independent of resting state. Dispose phases with their existing slots when switching, leaving or destroying the world. No additional remote arguments or persisted state are needed.

## Risks / Trade-offs

- An exterior camp could float on relief or conflict with another plot → reserve flat terrain, sample grounding and check all eight orientations and final plot bounds.
- Later walls or district houses could block access → one shared approach reservation plus a side gate, tested at levels 5, 20 and 50.
- Random shortcuts could pass through the fire → adjacent ring goals and native path observations, with a margin for rig width.
- Per-tick goal changes could prevent arrival or overload pathfinding → retained goals, scheduled pauses and existing navigator throttling.
- Slow speed could leak into battle or a replacement → explicitly restore normal speed on command transitions and initialize each spawn independently.
- Existing runtime tests assume troops stay near the old fixed rally → update assertions to observe arrival and bounded movement over multiple cycles, retaining protection and lifecycle coverage.

## Migration Plan

Implement and verify the layout/visual slice first, then regroup/resting movement. Existing training purchases rebuild into the campfire appearance on startup without a migration or repurchase. Add geometry and command fixtures before behavior edits, run the complete Studio module suite with a fake store and preserve the neutral-opponent regressions. Use a single solo Studio playtest for native construction input, return paths, three-slot wandering, command interruption, a regrouped replacement, growth through perimeter stages and transformed-map checks. Record the camp view and behavior evidence in docs/PLAYTEST.md. No teleports or published-storage changes require a client/storage migration test. Rollback restores the previous visual/site and fixed regroup branch while keeping saved trainingLevel intact.
