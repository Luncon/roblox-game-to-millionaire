# Design

## Context

The completed first milestone supplies shared offers, four one-time building tracks, an eleven-scalar profile, stable per-track floor contact latches and three independent army slots. See proposal.md for the next slice. Current farm capacity is constant and building maxima are hardcoded at one; pending army deadlines already snapshot death-time tuning.

## Goals / Non-Goals

**Goals:** Extend the existing server-authoritative purchase/save loop, retain old prices and stats unless the respective workshop is owned, and make the next unlocks visible and reachable.

**Non-Goals:** New troop slots/classes, combat-stat bonuses, offline income, checkpoint 20, healing, later tiers or matchmaking.

## Decisions

- Keep one canonical shared offer policy. Building descriptors gain frozen tier entries and maxima; legacy field/title/base-price metadata remains readable. Farm/worker II use current+1 offers at 12. Workshops have one purchased level. Weapon/armor offers calculate the final ceil(base × 0.95) price independently; immutable combat tracks stay unchanged.
- Retain the base-capacity constant for compatibility and add state-dependent storageCapacity. Schema, accrual, collection, HUD and world labels use this function. Settle old-rate, old-capacity whole intervals and reset fractional time before successful farm, worker or storage upgrades, preventing retroactive output or saved full-time income.
- Add blacksmithLevel, armorerLevel and storehouseLevel to copied states with missing-only zero defaults; save fourteen scalars. Validate owned tier unlocks, workers ≤ farm, Farm I for storehouse, capacity-dependent reserves and Barracks V/VI achieved levels 8/14. Army camp accepts barracks ≥IV. Keep the same version-one store/envelope and lease fences.
- Add Barracks V and VI directly to the existing track. The first four delays/prices remain unchanged. Capacity remains two in both new tiers; the optional camp still adds one. Existing death closures keep their deadline, while future deaths read the new tier.
- Reuse farm/worker pads for the next available tier. Move farm upgrades to local (-48,-145), separate from collection at (-24,-145), and reserve the extra rural access area before terrain/scenery generation. Logical track latches survive replacement as before.
- Purchased Blacksmith/Armorer sites use local (-42,34)/(42,34), with pads at z51; Storehouse uses (0,45) and a pad beside it at (20,45). Keep pads within their unlock-stage foundations and prompt users outside future walls. Reserve sites and forecourts from district lots through 50. Move the existing level-13 garden while retaining its feature identity. Both workshops use existing civilization architecture with forge/armor details. Farm II adds cultivation, Worker II adds one visual worker, and Storehouse adds visible storage.
- Expand the infrastructure cache key with all purchased tiers; reserve ticks only update labels. New balances and ownership pass through normal server snapshots/HUD. No client purchase remote or new external asset is introduced.
- Add an isolated --solo --expansion runner using the existing fake bootstrap and real client E input. Keep the previous --development workflow available for regressions.

## Risks / Trade-offs

- Workshop prices could diverge across UI and server → use offers for all final displayed/charged prices and verify independent rounded discounts.
- Profile compatibility could reject valid old armies → cover missing defaults, Farm II/Worker I, Barracks VI/camp and all-civilization round trips.
- Farm/storehouse upgrade could credit blocked time → injected-clock tests plus a real full-reserve expansion check.
- Functional sites could collide with later districts or pads → all thirteen civilizations at unlock/50, transformed maps and standing clearance tests.
- New farm access reservations could change terrain counts → run existing topography/landscape budget checks and keep the 2,000-part landscape ceiling.
- Faster replacements could unintentionally expand armies → assert three-slot maximum and living/dead-slot identity through purchases.

## Migration Plan

No destructive data migration: missing fields default during validation, preserving old values and gates. Run fresh fake-store suites, then one ordinary Studio playtest with real purchases, timers and switching. Validate production and test builds separately and restore normal Edit startup. Live storage, connected multiplayer and device checks remain separate evidence. A rollback writer must retain all fourteen fields and expanded tier/cap validation.
