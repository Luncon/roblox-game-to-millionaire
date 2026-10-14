# Civilization roster

## Purpose

Let players choose the agreed historical civilizations and recognize their
settlements through themed prototype architecture and presentation.

## ADDED Requirements

### Requirement: Full civilization selection

The selector SHALL offer Sparta, Seneca, Britain, Mongols, Vikings, Persia,
Sengoku Japan, Mauryan India, Spain, Egypt, Rome, Ottomans, and Ming China with
the reference periods in GAME_VISION. One owner per civilization and at most
eight plot owners SHALL remain enforced.

#### Scenario: More choices than plots
- **WHEN** eight players have claimed distinct civilizations
- **THEN** a ninth request for another civilization is rejected as full
- **AND** no existing claim changes

### Requirement: Reachable roster controls

All choices, availability, refresh, and notices SHALL remain reachable by
scrolling at narrow viewport widths without overlapping each other.

#### Scenario: Select the last entry
- **WHEN** an unclaimed player scrolls to Ming China on a narrow screen
- **THEN** its choice and availability are readable and can be activated

### Requirement: Civilization-themed settlements

Each civilization SHALL have an identifiable name, accent color, and themed
placeholder architecture. Settlement expansion SHALL preserve the selected
civilization's theme and ownership display.

#### Scenario: Claim and upgrade a themed plot
- **WHEN** a player claims a civilization and expands the settlement
- **THEN** the civilization remains identifiable in the sign and buildings
- **AND** unrelated Workspace objects remain intact


### Requirement: Centered upgraded settlement

Upgraded geometry and respawn locations SHALL follow the plot's current position
and rotation. A Citadel's perimeter SHALL remain centered on its foundation,
with all structures inside its footprint and its physical buttons unobstructed.

#### Scenario: Move and rotate an upgraded plot
- **WHEN** a plot or generated map moves or rotates and the settlement is upgraded
- **THEN** the buildings, perimeter, and spawn stay aligned with that plot
- **AND** the coin, settlement, weapon, and armor pads remain usable
