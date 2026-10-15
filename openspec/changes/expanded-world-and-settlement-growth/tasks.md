# Tasks

## 1. Gradual progression and compatibility

- [x] 1.1 Add shared configurable 50-level settlement/weapon/armor tuning and bounded fractional stat curves; verify all levels, prices, settlement gates and maximum purchase rejection in Studio specs.
- [x] 1.2 Widen saved settlement/gear validation against independent track limits without changing keys/schema or resetting existing progress; verify old and level-50 round trips, malformed values and barracks limits.
- [x] 1.3 Update physical floor controls for early tiers and stable higher-tier purchases, accurate lock feedback and fractional player/NPC equipment; verify native purchases, no entry-latch repeat purchases, inherited stats and exactly-once kill rewards.
- [x] 1.4 Document the stat curve, costs, unchanged barracks limits and existing-save rebalance in economy/profile docs; check values against delivered tuning and recorded balance comparisons.

## 2. Settlement construction

- [x] 2.1 Replace four-stage overlapping construction with deterministic gradual features and 13 themed district/landmark styles; verify every level adds detail, all footprints fit and identity remains incorporated.
- [x] 2.2 Preserve forecourt, barracks/spawn and exit clearance through growth, switching and transformed rebuilds; verify small/intermediate/final settlements and measured final-world part counts.
- [x] 2.3 Document settlement growth, architecture milestones and configurable cap; compare starter/intermediate/final illustrations and measured sizes with the delivered builder.

## 3. Expanded landscape and battlefield

- [x] 3.1 Expand the eight-plot ring, reserved final footprints, combat field, ground and derived roads; verify transformed geometry, pairwise separation, supported spawns and protected combat boundaries.
- [x] 3.2 Add five visibly distinct biome regions, waterways, dry crossings and battlefield cover inside the generated world; inspect actual overview and ground-level visuals and verify owned cleanup and critical route clearance.
- [x] 3.3 Verify real automatic troop movement from starter/intermediate/final settlements into the expanded field, melee/ranged engagement and protected targets using single-window engine fixtures; identify owner-interface doubles and keep actual multi-client evidence separate.
- [x] 3.4 Document world dimensions, biome layout and traversal/cleanup boundaries; check the guide against actual map geometry and observed navigation.

## 4. Verification and documentation

- [x] 4.1 Update HUD, setup and playtest evidence; inspect early/late/MAX state and report exact runtime/device limitations.
- [x] 4.2 Run relevant module, persistence and native solo regressions, resolve independent review findings, build production/test places and pass strict OpenSpec validation; remove temporary Studio fixtures and verify production isolation, reporting multi-client regressions separately.

## Testing preference

The user reported laptop crashes from simultaneous Studio windows and requested
one playtest at a time, preferring solo testing. Extra clients are permitted only
when needed and opened slowly. This milestone uses single-window engine fixtures
for geometry, native inputs and NPC behavior; prior genuine multiplayer evidence
is retained as historical evidence, and new connected-player checks are not
claimed when only owner-interface test doubles were used.
