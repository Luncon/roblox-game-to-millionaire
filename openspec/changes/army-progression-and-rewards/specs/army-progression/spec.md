# Army Progression

## Purpose

Expand automatic civilization armies through settlement-gated barracks upgrades and an independently maintained ranged troop.

## ADDED Requirements

### Requirement: Barracks timing upgrades
Barracks SHALL start at level 1 when settlement stage 2 unlocks them. Purchases to levels 2, 3, and 4 SHALL require settlement stages 2, 3, and 4 and cost 30, 75, and 150 coins. Their future respawn delays SHALL be 14.5, 14, and 13.5 seconds, respectively.

#### Scenario: Buy a faster barracks
- **WHEN** an eligible owner buys the next barracks level
- **THEN** the exact price is deducted and future deaths use a delay 0.5 seconds shorter
- **AND** an already pending replacement deadline remains unchanged

### Requirement: Independent ranged slot
Barracks level 4 SHALL automatically deploy one ranged troop in addition to one melee warrior. Each slot SHALL have its own replacement timer. Gear upgrades SHALL affect both living troops and replacements. Resets and settlement rebuilds SHALL preserve both slots; departure SHALL cancel both.

#### Scenario: Complete the third barracks upgrade
- **WHEN** the barracks reaches level 4
- **THEN** one civilization ranged troop appears without replacing the warrior or its pending timer
- **AND** each owner has at most one living troop of each class

### Requirement: Civilization ranged combat
Every civilization SHALL have appropriate ranged equipment and visible projectiles. Ranged attacks SHALL use server collision checks, finite range and lifetime, hostility and arena protection, and shared final-hit rewards. Obstacles and protected actors SHALL block shots without damage.

#### Scenario: Ranged troop attacks an enemy
- **WHEN** a ranged troop fires at a visible enemy inside the arena
- **THEN** a projectile travels toward the target and damages a valid enemy on collision
- **AND** a blocked, friendly, neutral, stale, or outside-arena hit deals no damage

### Requirement: User-provided civilization melee models
Spartan, British, Japanese, Seneca, and Mauryan melee warriors SHALL use cloned user-provided R6 templates with original clothes and headwear, live gear upgrades, navigation, and combat. Stored and placed originals SHALL remain unchanged. Other troops SHALL retain generated models.

#### Scenario: Spawn and upgrade a custom warrior
- **WHEN** one of the five mapped civilizations deploys a warrior
- **THEN** its custom model walks using the troop navigator and inherits the owner's gear levels
- **AND** its original clothes and headwear survive upgrades without modifying the source template

### Requirement: Template rig preparation
Custom clones SHALL remove embedded code and external physics links, unanchor parts, and normalize R6 body connections before spawning. Invalid or absent templates SHALL fall back to procedural warriors.

#### Scenario: Prepare a custom template
- **WHEN** a custom warrior is created
- **THEN** its unparented clone is sanitized and its body and cosmetic parts form a movable R6 assembly
- **AND** a template that cannot form a valid R6 rig uses a procedural replacement
