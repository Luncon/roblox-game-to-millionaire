## Purpose

Equip user-supplied civilization cosmetics on players and troops while preserving
custom troop identities, equipment progression and authoritative combat behavior.

## ADDED Requirements

### Requirement: Civilization and role matching
Players and eligible generated troops SHALL wear the supplied hat and weapon visuals for their civilization and role. Egyptian players SHALL wear Pharaoh headwear and Egyptian troops SHALL wear Anubis headwear. Custom melee troop skins SHALL retain their original headwear and clothing.

#### Scenario: Equip imported gear
- **WHEN** a civilization's player, melee troop or ranged troop receives equipment
- **THEN** mapped imported visuals replace the corresponding placeholders, with custom melee headwear preserved and ranged weapons appropriate to their class

### Requirement: Safe cosmetic equipment
Imported equipment SHALL be visual-only, rigidly attached and noncolliding. Embedded logic, forces and imported combat metadata SHALL not control gameplay. NPC equipment rebuilds SHALL retain explicit server physics ownership. Missing or invalid visual templates SHALL retain the procedural equipment fallback.

#### Scenario: Import a model with embedded logic
- **WHEN** the server clones the supplied visual
- **THEN** executable and physical control objects are absent, the original remains unchanged, and damage and health still follow the existing server upgrade tracks

#### Scenario: Rebuild a live troop's gear
- **WHEN** a live troop receives upgraded equipment near a connected player
- **THEN** its rebuilt assembly remains explicitly server owned during subsequent physics and movement

### Requirement: Clean equipment lifecycle
Upgrades, respawns, civilization switches and clearing equipment SHALL replace owned cosmetics without accumulating duplicate hats, weapons or grips or deleting unrelated avatar items.

#### Scenario: Upgrade and switch
- **WHEN** equipment is reapplied at a new level or civilization
- **THEN** exactly the current role's owned visuals remain attached and custom troop clothing and unrelated avatar items survive
