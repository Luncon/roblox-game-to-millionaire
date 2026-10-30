# Design

## Context

The sandbox has building-owned original infantry, ten one-cost slots, server
numeric combat, and client interpolation of original poses. The import workbench
contains eleven animal models with inconsistent scales and0–41joints;32scripts
include independent touch damage, riding controls, physics, sound and replacement
logic. Several imports also contain animation-editor data and invisible proxies.

## Goals / Non-Goals

**Goals:** safe recognisable animals for all thirteen fantasy-themed mounted
roles; individual facilities; two-slot accounting; coherent seated riders,
ground contacts and smooth movement; proven ordinary UI purchase/capture.

**Non-Goals:** player riding, flying, new research, mounted powers/charge skills,
production source changes, importing arbitrary controllers or new live storage.

## Decisions

1. Archive the raw eleven-root pack outside all Rojo mappings. Audit all imported
   code before any Play, disable it in the workbench and export fresh inert
   templates under ServerStorage.MountTemplates. Remove scripts/remotes/seats/
   physics/controllers and editor metadata; preserve meshes/CSG and original
   visible geometry, part identities and source backup. No model is re-downloaded.
2. Shared MountConfig owns animal identity, template and facility names. Persia
   derives a leopard appearance from the supplied tiger. Existing original
   civilization outfits/equipment create the seated rider. Animal proportions
   are normalized by visible horizontal extent, with practical overall lengths
   around3–4.6studs, not oversized source editor bounding boxes.
3. MountStructures builds thirteen distinct quarter-scale12×10facilities. Mark
   only their floors as valid queryable support; all other decoration remains
   inert and excluded from authoritative shots and commander collisions.
4. One mount building yields one mounted actor at capacity cost two. Stable
   building-order allocation uses weighted group costs; pending groups backfill
   without resetting unrelated actors. Battle independently rejects overweight
   manifests. Preserve schemaVersion1with missing-only mount inventory defaults.
5. Mounted actors reuse the exact original melee tactical helpers and cadence,
   with a shared300HP/48damage/9speed budget. Ordinary roles and neutral garrisons
   remain unchanged. Avoid a duplicate tactical helper closure or production
   config mutations. Contact/range/visibility/life authority stays on the server.
6. Rebuild safe clone anatomy into an explicit joint graph, retain the original
   R6 rider at the root and use marked animal contacts rather than rider feet.
   Procedural per-frame strides fit the animal's anatomy, avoiding permission-
   dependent uploaded animations. A backwards-compatible mounted pose payload
   supplies movement metadata; foot pose packets and face visibility stay intact.
7. Generated test projects include native mount factories/scenes and an explicit
   Coin-only funded UI fixture. Ordinary review remains200Coins. Original user
   imports remain in their workbench; no verification runs their scripts.

## Risks / Trade-offs

- Unrigged85-part tiger and203-part crocodile → anatomy grouping, eliminate
  irrelevant invisible control geometry and measure actual posed geometry/perf.
- Imported facing/pivots vary → use visible anatomy and explicit per-template
  normalization; verify feet, rider placement and front direction natively.
- Rider/mount and gear can separate → solve one joint hierarchy in source and
  local render, with original grips and source-decal hiding regressions.
- Two-slot capacity can exceed ten via a direct manifest → validate weighted
  allocation at both State and Battle boundaries, including one-free-slot cases.
- New stock keys can invalidate old fake state → missing-only migration and
  malformed-load fixtures; no real profile stores are used.

## Verification

Pure tests cover price/replay/reclaim/weighted cap/life healing/capture using the
exact original helper adapter. Native tests cover all13facilities and animals,
immutable templates, scripts/physics exclusion, gait contacts, rider attachments,
source/client parity and real purchase/placement/hammer/E capture input. Keep the
user's workbench Edit window and existing Play intact; use at most one additional
verification Play. Published/mobile/adverse-network claims require separate tests.
