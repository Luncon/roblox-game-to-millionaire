# Proposal

## Why

The expanded world still reads as a flat board with circular biome patches and
regularly spaced bumps. The user wants actual topography and a naturally
asymmetric landscape.

## What Changes

- Add connected rolling ground and unequal ridges, dunes and highlands with
  irregular placement, silhouettes and biome edges.
- Shape waterways and scenery to follow the land, preserving dry approaches.
- Keep final settlement footprints, floor controls, entry and troop corridors
  level and unobstructed; verify navigation and combat on the resulting map.
- Use deterministic owned geometry with a bounded part count so rebuilds and
  cleanup preserve developer geometry and the single-window testing workflow.

The topography/asymmetry outcome is confirmed. Exact landform placements,
heights and the generated geometry technique are implementation choices.
New formations, economy changes, settlement layouts and cross-server routing
are outside this change.

## Capabilities

### New Capabilities

- `natural-world-topography`: Asymmetric traversable relief, integrated landscape
  dressing, protected infrastructure and safe owned generation.

### Modified Capabilities

None. The expanded world change remains the foundation for eight protected plots.

## Impact

Landscape generation and focused Studio tests, plus world/playtest documentation.
No profile schema, currency, ownership or combat authorization changes and no new
dependencies. Production/test Rojo mappings must include any added Luau modules.
