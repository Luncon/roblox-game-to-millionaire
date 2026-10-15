# Design

## Context

See proposal.md for scope. Existing progression starts every track at one, uses five hardcoded saved scalars and two army slots keyed by class. Settlements build incrementally through 50 levels; main hall, barracks and growing districts already occupy fixed lots. All automation must inject a fake profile store.

## Goals / Non-Goals

**Goals:** Add a complete first building/economy/command loop using existing authority and save fencing. Keep unchanged progression and cosmetic curves intact.

**Non-Goals:** Later economy tiers, new combat classes, offline accrual, measured endgame pacing, matchmaking or construction timers.

## Decisions

- A shared SettlementDevelopment policy owns track-to-field metadata, new zero-to-one building offers, prerequisites, farm tuning and capacity. Existing UpgradeTracks keeps combat and old prices. This avoids treating an unfamiliar track as settlement by fallback.
- Add optional validated fields to schemaVersion 1: trainingLevel, farmLevel, workersLevel, armyCampLevel, farmCoins, extraTroopClass. Missing new fields receive defaults; explicitly invalid fields reject the profile. Existing settlement 10–50 states are valid without new buildings. Retain current store keys and lease logic; no destructive migration.
- Farm clocks exist only in live economy accounts. Server ticks commit whole five-second intervals to a saved reserve, capped at 60. Replacement/open resets the clock. Lost authority and full reserves discard blocked intervals. Collection is an atomic reserve-to-wallet transfer through normal owner/proximity-checked pads. No client-supplied money or elapsed time.
- Buildings and pads share stable settlement-local anchors. Armory sits in the right courtyard, barracks controls beside its entrance, training and camp in the front courtyard. Farmland flanks the arena approach around local z=-170, outside the final 128-stud half-width; worker camp and collection sit alongside. Reserve these areas in terrain/scenery sampling and retain the central road. New purchased structures update independently from the level-based settlement cache.
- Passive workers use small anchored animated rigs with no Humanoid combat registration or pathfinding. A bounded shared service animates tending and ticks active owners. This avoids adding many pathfinding agents to eight settlements.
- Army slots have stable IDs warrior, ranged and camp, separate from their current warrior/ranged kind. Existing public slots remain compatible. The camp kind is chosen at spawn; selection never replaces a living rig or reschedules a deadline. Orders are transient and reset to advance when a civilization is selected.
- Commands accept only advance/hold/regroup enums through a rate-limited server endpoint. Destinations come from the server; hold clears pursuit, regroup cancels projectiles and returns to the protected home rally. Client buttons unlock after training purchase and expose camp class selection with next-respawn wording.
- Pads consult the same offer policy as server purchases. Missing prerequisites remove pads while a small main-hall checklist explains the block. Unaffordable available pads stay red and labeled; completed one-time pads disappear. Keep eligible pad instances stable across farm ticks.

## Risks / Trade-offs

- New prerequisites change old all-level purchase fixtures → update fixtures to buy required buildings, retaining exact charge assertions.
- Rural layout could be overbuilt or bury crops → reserve maximum farm rectangles before terrain and scenery generation; inspect all eight plots at level 50.
- Timed income can rerender equipment unnecessarily → publish balances without army or appearance refresh; refresh only pad labels/status.
- Hold/regroup stale goals could keep chasing → stop navigation on command change and derive subsequent goals from the active order every think tick.
- New fields in old profile previews could be lost → canonical copied state fields pass through economy, save capture and owner UI.

## Migration Plan

Run focused fake-store module regressions, then ordinary single-window Studio Play for farm collection, purchases, switching and real NPC order/death behavior. Build production and isolated test places and verify production excludes fixtures. Record runtime evidence and limitations in docs. No published-client teleport test is needed for this local-server milestone. Rolling back to the previous binary would drop the new additive fields on its next save; retain a compatible decoder/writer if rollback is needed after live use.
