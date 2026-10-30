# Design

## Context

See proposal.md for motivation. Runtime sends combat/pose changes at10Hz;
anchored body-part transforms currently produce visible jumps even at60FPS.
OriginalTroops already solves original joints and grounds their soles. Battle
owns numeric actor lives, damage and capture; no physics body owns those rules.

## Goals / Non-Goals

**Goals:** interpolate those original poses per rendered frame, preserve joint
attachment/grounding and life isolation, make neutrals near peers, and add readable
outpost architecture without closing numeric troop paths.

**Non-Goals:** production renderer migration, client combat prediction, research,
fortification damage, save migrations, model imports or dependency changes.

## Decisions

1. Publish an atomic timestamped original pose per rig and render a local clone
   through a bounded interpolation history. Original joint poses remain authored
   by WarriorRig; the client interpolates them and solves existing equipment
   attachments. This avoids network updates overwriting local frame transforms.
   Raising all server body-part writes to60Hz would multiply replication work.
   A versioned ASCII model attribute carries timestamp, life, root, ground and
   six original body joints in one snapshot. Keep at most eight samples, render
   150ms behind synchronized server time and reset gaps over0.5seconds. This first
   fix retains server posed bodies for compatibility with existing native fixtures;
   reducing their replication is a separate optimization, not a claimed benefit.
2. Hide the source locally only after its render clone is ready. Track source
   body/display visibility and restore it on teardown. Replaced lives never share
   history. Stop at the last known pose when updates stop rather than drift.
   Decals and inherited Texture objects have separate local transparency from
   BaseParts: hide both source types, reset cloned decal modifiers and restore
   the exact prior modifiers when removing the local copy. Otherwise source faces
   appear ahead of the delayed visible bodies.
3. Derive neutral profiles from owned profiles with a0.95 health/damage/speed
   multiplier. Preserve identical range and timing. This replaces the former
   unrelated weak test-defender stats and4speed/9range caps; production is untouched.
4. Give every first outpost a small native ancient frontier compound. Keep wall
   openings aligned to approach corridors and capture-center access. Decoration
   is static, inert and excluded from combat raycasts so it cannot invalidate
   numeric movement without a future pathfinding/fortification feature.

## Risks / Trade-offs

- Interpolation adds a short visual delay → bounded history, no client hit authority,
  and native observation of contact/health/life transitions.
- Grounded endpoint poses can sink during rotation interpolation → check posed
  soles and maintain ground clearance on render frames.
- Clone setup can race replication → wait for complete geometry/protocol and leave
  the source visible until ready; disconnect and clean up life-scoped listeners.
- Stronger defenders may stop an outnumbered test army → test with ordinary mixed
  building-owned armies and retain honest losses and all capture rules.
- Decoration can obstruct players or shots → inert geometry, open corridors and
  actual native approach/capture checks, bounded part counts.

## Migration Plan

Build a separate sandbox verification place; retain the user's current Play.
Run pure regressions, original native rig checks, rendered movement measurements
and ordinary UI capture. Update vault evidence and the next ordinary review build.
Published multiplayer, mobile and adverse network testing remain separate work.

Commander travel is set by the server on each fresh character to32studs/second,
using existing Roblox player input and preserving independent troop speed tuning.

Roblox documents [PreRender](https://create.roblox.com/docs/reference/engine/classes/RunService)
as the client frame hook and
[LocalTransparencyModifier](https://create.roblox.com/docs/reference/engine/classes/BasePart)
as local-only visibility control. No new server action or saved state is introduced.
