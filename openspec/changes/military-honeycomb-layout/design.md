# Design

## Context

The reference at docs/assets/Pasted image 20261028150336.jpg has pointy-top hexagons with three left sides. Current ResearchTree uses 80×69 flat-top hexagons spaced 104×90 pixels apart and independent connector frames. The server research catalog already supplies 29 stable IDs and three children of Army Training.

## Decisions

- Introduce a pure presentation layout with pointy-top axial coordinates. At height 96, width is 96√3/2 and row spacing is 72. Adjacent cells share a full polygon edge. Derive canvas bounds and offsets from all 46 cells.
- Place Army Training at the origin and its three starting neighbors northwest, west and southwest. All other military cells extend left; civilian future cells occupy the right. No gameplay catalog coordinates, dependencies or saved state are edited.
- Visual contact does not redefine prerequisite relationships. Officer Training already has four children and the touching grid creates incidental neighboring edges; selected-node prerequisite text and server rules remain authoritative.
- Remove connector frames while retaining six polygon outlines per hexagon. Paint upright hexagons with existing native UI primitives. Centered inscribed 60×60 buttons do not overlap and remain at least 44×44 at minimum zoom. Where additional polygon selection is provided, ignore clipped/hidden regions and drag gestures.
- Reset only obsolete client-session pan state once for the new layout; preserve later pan/zoom/selection across rendering and minimization. Keep the detail panel, availability colors and guarded Research action.

## Risks / Trade-offs

- Rectangular hitboxes overlap diagonal tiles → use inscribed buttons and verify actual native clicks at shared-edge neighborhoods.
- Short phone graphs clip large tiles → minimum zoom yields a 72-pixel hex; verify four established viewport sizes and navigation controls.
- User reference note already has uncommitted edits → read it without overwriting or staging those edits.

## Delivery

Run focused geometry tests, native rendering/selection/guard checks and the development gate. Update the Obsidian implementation note. Build and publish the reviewed UI update only to place 73839918762778 / universe 10770758443, retaining eight-player/private settings and live persistence.
