# Proposal

## Why

Miniature troops visibly jump between ten server poses per second. Neutral
defenders also have a large health/damage disadvantage instead of the small
disadvantage requested for their player counterparts.

## What Changes

- Draw movement and original authored poses smoothly on each client, with bounded
  interpolation and stable equipment grips, ground contact and life cleanup.
- Derive neutral health, damage and speed at95% of matching player role values;
  use equal reach and timing to avoid compounding the disadvantage.
- Preserve server combat/capture authority and original assets, and record native
  movement measurements rather than infer smoothness from rendering FPS alone.
- Build the capturable outposts into small ancient frontier camps with walls,
  buildings and decoration while preserving clear approaches and combat space.
- Double commander walking speed from16to32studs/second on spawn and respawn.

## Capabilities

### New Capabilities

- `miniature-army-presentation`: frame-based interpolation of original army poses
  with local rendering lifecycle and unchanged server authority.
- `miniature-neutral-balance`: near-peer neutral combat profiles.
- `miniature-outpost-scenery`: structured capturable frontier settlements.

### Modified Capabilities

None. The earlier miniature original-army change remains unarchived; this change
supersedes its neutral4speed/9reach tuning without modifying production settings.

## Impact

Only miniature sandbox server/client/shared modules, regression fixtures,
OpenSpec change artifacts and the shared Obsidian Markdown vault. No production
scripts, source templates, save fields, research, player controls or dependencies.
