## Purpose

Give the civilization battlefield a naturally asymmetric, traversable landscape
with actual relief while preserving settlement growth and safe troop access.

## ADDED Requirements

### Requirement: Naturally asymmetric relief
The generated world SHALL contain connected rolling ground and irregularly placed larger landforms. Heights, silhouettes and biome transitions SHALL visibly vary without repeating the eight-plot rotational pattern.

#### Scenario: Explore the world
- **WHEN** a player views the world from above and at ground level
- **THEN** unequal ridges, slopes, lowlands and irregular biome edges distinguish regions instead of a flat board of circular patches

### Requirement: Protected settlement infrastructure
Finished settlement footprints, upgrade controls, barracks deployment, entry spawn and shared troop corridors SHALL retain level supported ground. Raised land and decoration SHALL not block those spaces as civilizations grow.

#### Scenario: Deploy from different settlement sizes
- **WHEN** melee and ranged troops leave small, intermediate or completed settlements
- **THEN** real movement reaches the battlefield through dry accessible approaches without terrain blocking gates or floor pads

### Requirement: Integrated scenery and traversable combat ground
Scenery and waterways SHALL follow the landscape without buried or floating props. Battlefield relief SHALL remain within the existing damage height band for standing actors, with walkable slopes and dry crossings. Existing ownership, range and arena protections SHALL continue to apply.

#### Scenario: Fight across relief
- **WHEN** troops traverse and fight in the reshaped battlefield
- **THEN** movement and projectile impacts work on supported ground while protected or outside-arena targets remain immune

### Requirement: Bounded deterministic owned generation
The same world configuration SHALL reproduce the same terrain. Landscape generation SHALL use at most 2,000 static BaseParts and remain owned by the generated world so moves, removal and rebuilds preserve unrelated developer objects and global Terrain.

#### Scenario: Move or remove the generated world
- **WHEN** its model is transformed or destroyed
- **THEN** landforms, scenery and collision surfaces follow it and unrelated Workspace geometry and Terrain remain intact
