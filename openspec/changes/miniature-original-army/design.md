# Design

## Context

The first outpost change has a numeric lifecycle/capture kernel, simplified art
and poses. Original production uses WarriorRig, immutable imported templates,
Equipment/OutfitTemplates and CombatEncounter/CombatTactics, with separate medical
services. The user requests those identities and baseline behaviors in miniature.

## Goals / Non-Goals

**Goals:** exact original rig creation/animation and tactical helper reuse; stable
quarter-scale geometry; planted soles; slower travel and shorter ranged/support
coverage; preserved outpost authority and fake-store isolation.

**Non-Goals:** importing production Bootstrap, player weapons/profile services,
unlocking progression-gated formations/skills, adding research or changing source
assets. Original level-one equipment is the current baseline, without shield or
skill progression. Miniature source health/damage balance remains separate from
production progression; this change concerns identity, behavior, speed and reach.

## Decisions

1. Explicitly map the reviewed original helper closure under ServerStorage.OriginalArmy
   and the existing asset folders. Keep dependencies as modules without original
   services or bootstrap. The Node allowlist verifies the exact permitted paths.
2. Create roles through original WarriorRig.create/createNeutral, scale clones
   to0.25, disable the retained clothing Humanoid and keep original inert Tools.
   Apply original WarriorRig.animate, scaling its authored translation offsets
   and solving the clone's motor/weld graph kinematically. This retains outfits,
   grips and original poses without dynamic miniature physics or player pickup.
3. Sample support surfaces with raycasts, excluding characters, actor rigs and
   invisible noncollidable selection proxies. Explicitly mark the outpost footing
   as a support. Fit the lowest posed R6 leg corner to the sampled height rather
   than the entire model's bounding box; retain a tiny0.005stud sole tolerance.
4. Keep numeric army identity/death/respawn/capture ownership. Feed exact original
   encounters a full-scale virtual coordinate view per outpost; their plans map
   back to miniature movement with6/4speed caps. Use real, unparented Model life
   identities for APIs that require Instance filters, never physics actors or
   source rigs. Retain final Battle life/range/visibility authority.
5. Reuse original medic planners and MedicalService through the virtual adapter.
   Ranged flight uses scaled original projectile speed/range with numeric sweeps
   and fresh target-life validation; actual original TroopProjectile cannot raycast
   its virtual coordinates against the visible map. Rendering remains visual-only.
6. Read-only sandbox wrappers clone original RangedConfig/MedicalConfig, overriding
   range40/28virtual (10/7actual) and medical recoveryDistance24virtual so critical
   recovery remains inside the shorter healing range. Neutral ranged gets a final
   nine-stud cap. All other original constants/variants stay unchanged.

## Risks / Trade-offs

- Authored RestC0 attributes are not guaranteed to scale with joints → keep original
  baselines, scale generated pose translations once and compare real native joints.
- Rich source cosmetics and anchored per-part poses cost more than box figures →
  retain caps and measure native scope rather than claim phone/server performance.
- Virtual coordinates cannot directly use physical original projectiles → validate
  numeric flight and same-life contacts, then observe native shots/capture.
- Config reuse can accidentally alter production → no src/assets edits; wrappers
  freeze clones and original/default/preview mappings remain unchanged.

## Verification

Run exact original planners under explicit engine doubles plus capture/authority
regressions. Native fixtures compare39culture roles and2neutral roles against
independently created/scaled originals, including five custom sources, garments,
equipment, grips, poses, ground0/.4and an avatar above the support ray. Repeat the
actual UI outpost loop with original models, shorter ranges and slower speed.
Record source fingerprints, measured sole clearance and any remaining device or
published multiplayer limits. Preserve the user's combat Play and use only one
additional verification Play; close owned test windows after evidence capture.

Roblox [model scaling](https://create.roblox.com/docs/reference/engine/classes/Model)
and [Humanoid state-machine](https://create.roblox.com/docs/reference/engine/classes/Humanoid)
documentation supports the explicit scaled-joint/disabled-physics adapter.
