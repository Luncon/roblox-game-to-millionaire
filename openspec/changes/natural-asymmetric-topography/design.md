# Design

## Context

The 1,600-stud world currently decorates a flat ground Part with ellipse-shaped
biome patches, radial hills and a straight river. Eight 256-stud final plots and
28-stud radial approach roads must remain usable. Combat accepts actor roots
within 16 studs of the arena plane. See proposal.md for the requested outcome.

## Goals / Non-Goals

Deliver actual collision-supported relief and irregular visual geography using
ordinary owned Roblox geometry. Keep currency, claims, stored progression and
server combat authority intact. This does not change the eight-plot ring or
introduce terrain editing tools, swimming requirements or client terrain authority.

## Decisions

- Use a deterministic sampled height field with broad unequal landforms and
  modest noise. Native sloped geometry forms connected surfaces; global voxel
  Terrain would complicate transformed fixtures and risk developer terrain.
  EditableMesh would introduce permission/publishing requirements unnecessary
  for this prototype. Prefer simple native geometry and measure the result.
- A conforming nonuniform axis grid uses 40-stud coordinates inside the central
  640-stud square and 160-stud coordinates farther out. Shared coordinate lines
  avoid T-junction seams while retaining battlefield relief between roads;
  whole-cell flattening on a uniform 80-stud grid erased every arena vertex.
  Shared triangle vertices determine rendered surfaces and sampled prop heights.
  Thin native wedge halves form triangles, offset below the intended surface;
  flat cells collapse to a solid flat Part. Cell fill and boundary skirts close
  accessible undersides. Samples and normals remain local to the generated world.
- Blend elevation to flat ground around final plot reservations, radial roads,
  entry, central plaza and water crossings. Flatten vertices of intersecting
  cells so interpolation cannot project a slope across a reserved area. The
  flat surface is 0.15 studs above the world origin. Inside the field, cap surface relief
  at six studs to leave space for standing Humanoid roots within the
  unchanged 16-stud combat band. Outer ridges can be taller, tapering before the
  combat boundary. Sample slopes and actual raycast surfaces, not only metadata.
- Irregular biome boundaries and terrain-following props replace circular patch
  decals. Water follows a winding lowland with dry crossings aligned to affected
  approaches; no mandatory swimming or deep-water navigation is added.
- Keep landscape geometry at or below 2,000 static BaseParts; target fewer where
  practical. Reuse fixed coarse sampling rather than one Part per stud. Inspect
  silhouettes and traversal before accepting a visually flat or expensive mesh.
- Keep field gradients within approximately 15 degrees; use wider transitions
  where reserved flat corridors meet rolling ground. Scenic outer ridges may
  rise farther but taper down before entering the combat region.
- All coordinates are local to the owned world. Building is deterministic; normal
  model transforms and destruction carry or remove every surface and prop.

## Risks / Trade-offs

- Terrain seams or inverted wedge colliders → verify real raycasts and walk an
  actual Humanoid over representative slopes in Studio.
- Height blending encroaches on pads or roads → test full extents of finished
  plot reservations and critical corridors, including transformed fixtures.
- Raised props exceed combat height or appear suspended → ground scenery using
  the sampled rendered surface and test actor-height headroom.
- More parts cost laptop resources → measure generated counts, keep one Play
  window, and report hardware limits rather than infer FPS from geometry counts.
- Landscape asymmetry can affect combat routes → preserve equivalent clear
  radial approaches and measure actual melee/ranged arrivals.

## Migration Plan

Sync Luau modules and restart ordinary Play. No save keys, schema or stored
levels change. Reverting the terrain generator restores the earlier map without
data migration. Automated tests inject fake storage; Studio verifies generated
surfaces, movement, projectile impacts and views. Published-client performance
and multi-owner networking remain separate verification.

References: Roblox [WedgePart](https://create.roblox.com/docs/reference/engine/classes/WedgePart),
[Humanoid slope handling](https://create.roblox.com/docs/reference/engine/classes/Humanoid#MaxSlopeAngle)
and [pathfinding](https://create.roblox.com/docs/characters/pathfinding).
