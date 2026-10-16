# Design

## Context

See proposal.md for motivation. Native inspection reproduced Sparta 12 with pillar/podium bottoms at foundation-local 2 and foundation top at 1. District architecture shares those offsets. Fixed pitched roof heights fail at width 42, pagoda/yurt roof sections have explicit gaps, starter towers lack a base, and grand longhouses intersect the level-30 perimeter and ceremonial gate. Purchased houses reuse the district constructor; rural ground is lower than the settlement foundation.

## Goals / Non-Goals

Goals: repair the shared construction rules, test actual native shapes, preserve art themes and existing gameplay access. Non-goals: new gameplay, replacement art assets, profile migrations or editing the user's committed place binary.

## Decisions

- Keep existing body/facade heights where practical and provide grounded footings beneath district houses and monuments. This avoids a global world/foundation shift that would move pads, spawns and troop routes. Correct individual post bases and surface elevations directly.
- Share a server pitched-roof constructor between starter and district builders. Derive panel centers from the wall top, width, slope and thickness; two native wedge prisms fill the attic. Existing overhangs and materials remain configurable. Rooftop ornaments follow the resulting roof surface.
- Keep the grand longhouse center and width but reduce its depth to 38, inset its end posts and update facade placement. Move the ceremonial gate forward to z -34. Moving the whole hall backward was rejected because it violates the level-30 footprint and worsens perimeter penetration. Classical podiums expand enough to support their front columns.
- Export transient house facade metadata to mount infrastructure labels against real walls rather than leave boards suspended beyond roofs. Ground rural worker footings using native exterior support; preserve soil top/worker feet while extending soil to ground and lowering crop bases. Fence rails receive posts; outdoor furnishings clear their house shells.
- Pads retain their original positions and interactions; child support slabs fill the gap beneath each pad to its current foundation or sampled exterior surface. Keeping supports inside the pad hierarchy preserves control enumeration and lifecycle cleanup.
- Tests use native shape contacts and independent roof-edge probes, with narrow tolerances for joint/skin offsets. Grounded contact graphs and cross-building checks cover all civilization/level combinations in base and transformed worlds. Focused regressions keep routine module runs small; the exhaustive matrix runs separately.
- All generation remains server-owned. No saved fields, currency, damage, networking or progression changes are required. Original source templates, global Terrain and the committed `.rbxl` stay unchanged. Only the coordinator operates one Studio session; the user requested a dedicated Git branch.

## Risks / Trade-offs

- Additional supports increase static geometry → retain the existing 400-part settlement contract and full bounds regression.
- Native wedge orientation or collider assumptions can differ from arithmetic → reproduce missing supports before edits, check actual native contacts and visually inspect representative themes and sizes.
- Intentional roof/body joints can resemble clipping → distinguish same-building assemblies from cross-building intersections and explicitly check wall tops against the roof exterior.
- Rural grounding and sign movement can disturb access → retain pad coordinates, preserve farmer soil tops and rerun native prompts, troop exits and camp return paths.

## Migration Plan

Fresh server generation and restored saved settlements use the corrected constructors automatically. No storage migration is needed. Restore normal Studio startup and delete owned fixtures after verification; revert the geometry source change to roll back.
