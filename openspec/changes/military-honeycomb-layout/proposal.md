# Proposal

## Why

The user wants the research tree to match the touching upright hexagons in the Obsidian screenshot. The current layout spaces flat hexagons apart and draws connecting lines.

## What Changes

- Join upright research hexagons along shared edges and remove cross-node connector lines.
- Grow the military half from Army Training's upper-left, left and lower-left sides. Keep inactive civilian placeholders to the right.
- Retain 29 existing military nodes, 17 future placeholders, selection, details, pan/zoom and guarded research actions.
- Use separate presentation geometry without changing saved research, prerequisites, prices, durations or effects.

The confirmed request is the visual honeycomb and three leftward starting directions. Pointy-top axial geometry and safe polygon selection are implementation choices. Gameplay rebalancing and new civilian research are outside scope.

## Capabilities

### New Capabilities

- `research-tree-presentation`: Connected hexagonal research presentation and safe selection across viewport sizes.

### Modified Capabilities

None.

## Impact

ResearchTree client, a shared pure layout module, focused geometry/native UI checks and Obsidian notes. Publish the tested presentation update to the existing authorized miniature game; no profile migration.
