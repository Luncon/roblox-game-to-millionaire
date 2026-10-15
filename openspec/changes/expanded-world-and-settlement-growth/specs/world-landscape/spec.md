## Purpose

Provide a spacious, varied world where eight growing civilizations can reach a shared battlefield fairly.

## ADDED Requirements

### Requirement: Room for eight finished settlements
The world SHALL arrange eight protected plots around a shared battlefield with enough separation for every level-50 settlement and its controls. Existing developer geometry SHALL be preserved.

#### Scenario: Fully occupied final world
- **WHEN** all eight plots contain finished settlements
- **THEN** their footprints do not overlap each other or the combat field and all remain on supported ground

#### Scenario: Generated world cleanup
- **WHEN** the generated world is rebuilt or removed
- **THEN** unrelated Workspace geometry and terrain remain intact

### Requirement: Diverse readable landscape
The world SHALL include visibly distinct grassland, forest, desert, snowy highland and wetland scenery, with waterways and dry crossings. Biome decoration SHALL preserve protected plot space, floor controls and critical movement routes.

#### Scenario: Explore the battlefield
- **WHEN** a player travels through the expanded world
- **THEN** biome materials, colors, vegetation, landforms and crossings visibly distinguish its regions

### Requirement: Traversable common battlefield
Every plot SHALL have an unobstructed dry approach to the shared battlefield. Automatic melee and ranged troops SHALL reach combat using real movement; settlement and out-of-field immunity SHALL remain authoritative.

#### Scenario: Troops from differently grown plots
- **WHEN** troops deploy from small, intermediate and finished settlements
- **THEN** they can leave their plots, cross the landscape and enter the battlefield without required swimming or blocked gates

#### Scenario: Protected targets
- **WHEN** an attacker targets its owner or an actor outside the combat field
- **THEN** the server rejects damage despite the enlarged visual map
