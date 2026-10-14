# Tasks

## 1. Economy rules

- [x] 1.1 Write and run failing Studio tests for one-coin earning, ownership, player isolation, burst/refill limits, affordability, sequential upgrades, stale purchases, maximum level, and cleanup.
- [x] 1.2 Implement progression configuration and server economy rules; pass those tests and document tuning and session-only lifetime.

- [x] 1.3 Extend and pass tests for independent weapon/armor prices, tiers, stale requests, and cleanup; document gear tuning.

## 2. Civilization roster and settlements

- [x] 2.1 Expand the catalog and themed settlement builder; pass Studio tests for all 13 IDs, eight-plot capacity, each theme, visible level growth, and release preservation.
- [x] 2.2 Replace fixed selector offsets with scrolling layout; verify the last choice is reachable in a narrow Studio client and document the roster.

- [x] 2.3 Fix final-tier centering; pass moved/rotated-plot spawn and geometry bounds tests and preserve clear access to all pads.

## 3. Playable economy

- [x] 3.1 Wire four physical pads with owner/distance/alive validation, replicated balances, and cleanup; pass pad/controller tests and demonstrate click earning and walk-on purchase without duplicate standing charges.
- [x] 3.2 Add the read-only economy HUD; demonstrate physical earning/purchases, maximum-level display, and HUD/coins/tiers after respawn; record input checks and limits.

- [x] 3.3 Equip civilization-themed weapons and armor on claim, upgrade, and respawn; verify model ownership, damage metadata, armor health, and preservation of unrelated avatar items.

## 4. Integration

- [x] 4.1 Pass the full Studio module suite, claim/economy multiplayer regression, strict OpenSpec validation, and production/test builds; record results and inspect the final diff.

## Workflow follow-up

- Saving per civilization is the next milestone requested by the user.
- Preserve the previous change's outstanding physical input check until verified.
