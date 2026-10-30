# Spec Delta

## Purpose

Present civilization research as connected hexagonal tiles whose selection and availability remain clear across supported screen sizes.

## ADDED Requirements

### Requirement: Connected upright military honeycomb
The research view SHALL use upright regular hexagons touching along shared edges, without cross-node connecting lines. Army Training SHALL have military neighbors on its upper-left, left and lower-left sides, with the remaining military tree extending leftward and inactive civilian context on the right.

#### Scenario: Open the military research view
- **WHEN** the player opens military research
- **THEN** Army Training is visible as the starting tile with three left-side military neighbors
- **AND** all 29 functional nodes form a connected touching layout
- **AND** the 17 future placeholders remain inert

### Requirement: Safe selection and navigation
Touching tiles SHALL preserve correct mouse/touch selection without overlapping actionable centers or selecting the wrong adjacent hexagon. Pan, zoom, focus, hidden-panel guards and selected-node details SHALL remain functional.

#### Scenario: Select a tile after navigating
- **WHEN** a player pans or zooms and then selects a visible hexagon
- **THEN** that hexagon's details are selected without issuing a research purchase
- **AND** dragging does not select an unintended neighboring tile

### Requirement: Presentation preserves research rules
The layout change MUST preserve existing military IDs, prerequisite requirements, prices, durations, modifiers and saved progress. The server SHALL continue validating research purchases independently of visual adjacency.

#### Scenario: Restore existing research progress
- **WHEN** a player opens the new layout with existing completed or active research
- **THEN** the same research progress and unlock rules are shown
- **AND** the existing guarded Research action remains the only purchase path
