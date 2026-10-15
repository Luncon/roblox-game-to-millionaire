## Purpose

Give every civilization a fitting complete outfit and matching weapon visuals
on players and troops, safely using free Creator Store and supplied assets.

## ADDED Requirements

### Requirement: Normal troop heads
Both generated troop classes SHALL have classic rounded Roblox head meshes and
a front-facing face. Existing custom melee heads and headwear SHALL retain their
original shape and proportions through equipment upgrades. Troop skin tones
and front-face expressions SHALL follow the civilization troop appearance policy.

#### Scenario: Generated troops spawn and upgrade
- **WHEN** a melee or ranged troop is generated for any civilization
- **THEN** its head uses the rounded Roblox Head mesh and a visible face
- **AND** upgrading equipment preserves the head, face and hat attachment

#### Scenario: Custom melee skin is cloned
- **WHEN** one of the five supplied melee skins spawns or upgrades
- **THEN** its existing head mesh, proportions and headwear are preserved
- **AND** its live body tint and face follow the troop appearance policy

### Requirement: Civilization troop skin tones and warrior expressions
Each civilization SHALL have a configured artistic NPC skin tone. Both troop
classes, including custom melee clones, SHALL use that tone and one warrior
front-face decal at spawn and after any gear refresh. The source models and
player avatar faces SHALL remain unchanged by this NPC policy.

#### Scenario: A troop upgrades or respawns
- **WHEN** a melee or ranged troop spawns or its equipment refreshes
- **THEN** its body colors match its civilization's configured tone
- **AND** exactly one warrior front face is active without replacing its head mesh
- **AND** clothing, headwear and authoritative combat behavior are preserved

#### Scenario: A player equips civilization gear
- **WHEN** a player selects a civilization or upgrades personal equipment
- **THEN** NPC skin-tone and face overrides do not apply to that player's avatar

### Requirement: Complete civilization wardrobes
Every civilization's player and generated melee/ranged troops SHALL receive a fitting body outfit, headwear and class-appropriate weapon visual. The five supplied custom melee skins SHALL retain their original clothes and cosmetics. Existing confirmed Egyptian player/troop headwear assignments SHALL remain.

#### Scenario: Choose any civilization
- **WHEN** a player selects a civilization or its troop spawns
- **THEN** its complete mapped outfit and appropriate weapon are visible without starter armor hiding the outfit or duplicate hats

### Requirement: Free and inert asset imports
New marketplace assets SHALL be verified free and importable before use, with source IDs and creators recorded. Stored and equipped copies SHALL contain only permitted appearance data; source scripts, forces, body control and gameplay metadata SHALL not run or change authoritative combat.

#### Scenario: Import a marketplace outfit
- **WHEN** an asset is prepared for the game
- **THEN** visual geometry and clothing remain while imported logic and physical controllers are excluded and originals remain untouched

### Requirement: Restored avatar wardrobe
Clearing civilization equipment SHALL restore the player's prior wardrobe without deleting unrelated avatar items or overwriting later external wardrobe edits. Repeated upgrades and switches SHALL retain a valid restore baseline. Late native avatar loading SHALL not overwrite the active civilization outfit.

#### Scenario: Switch and clear after an avatar edit
- **WHEN** a player changes civilizations, upgrades gear and later clears it
- **THEN** only the current civilization outfit is active before clearing and the current original avatar wardrobe is restored afterward

### Requirement: Stable equipment behavior
Imported outfit and weapon replacement SHALL preserve the existing server stats, progression, protection and reward rules, one NPC weapon grip and explicit server physics ownership. Missing or invalid assets SHALL use safe procedural fallback.

#### Scenario: Upgrade and move with imported gear
- **WHEN** an equipped troop upgrades and walks near a connected player
- **THEN** its clothing stays fitted, attached visuals move with their body anchors, and its server authority and combat behavior remain intact
