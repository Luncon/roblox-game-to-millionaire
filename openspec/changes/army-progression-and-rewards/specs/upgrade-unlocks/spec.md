# Upgrade Unlocks

## Purpose

Make settlement growth reveal tangible new tycoon purchase choices while retaining separate, shared player and troop equipment progression.

## ADDED Requirements

### Requirement: Softer equipment progression
Weapon tiers SHALL deal 10, 14, 19, and 25 damage. Armor tiers SHALL provide 100, 115, 135, and 170 health. Player and troop gear SHALL use these shared tiers. Live changes SHALL preserve missing health and not rebuild troops.

#### Scenario: Upgrade injured armor
- **WHEN** a tier-one actor with 30 missing health receives tier-two armor
- **THEN** its maximum health becomes 115 and current health becomes 85

### Requirement: New physical upgrade pads
Settlement stages SHALL create new floor pads for newly unlocked upgrade tiers. Weapon and armor tiers 2, 3, and 4 SHALL unlock at settlement stages 2, 3, and 4. Each purchase SHALL require its preceding tier. Purchased tier pads SHALL retire; locked and retired actions SHALL not charge.

#### Scenario: Expand to a village
- **WHEN** the settlement reaches stage 2
- **THEN** new weapon-tier-two, armor-tier-two, and barracks-tier-two pads appear
- **AND** a higher gear tier requires buying its preceding tier first

### Requirement: Owner access and safe placement
Ground purchases SHALL retain click, prompt, and walk-on input with ownership, distance, and entry-latch checks. New pads SHALL stay within current settlement bounds, clear buildings, and follow moved or rotated foundations.

#### Scenario: Access another plot's new pad
- **WHEN** a non-owner activates a newly unlocked upgrade pad
- **THEN** no purchase or currency change occurs

### Requirement: Settlement level cap
Weapon, armor, and barracks upgrade levels SHALL never exceed the owner's settlement level. Purchases above this cap SHALL reject without charging even when requested through a stale or hidden control. Reaching the cap SHALL require a settlement expansion before further purchases in that track.

#### Scenario: Reach the level-two cap
- **WHEN** a level-two settlement owner has level-two equipment and tries to buy level three
- **THEN** the purchase fails without changing currency or equipment
- **AND** expanding to settlement level three reveals the level-three purchase pad

### Requirement: Architectural civilization identity
Claimed plots SHALL display civilization and owner names on a civilization-styled part of the main building facade. The display SHALL remain within the building silhouette and leave the settlement view and ground controls unobstructed. Unclaimed plots SHALL retain a readable plot marker.

#### Scenario: Claim and expand a civilization
- **WHEN** an owner claims a civilization or expands its settlement
- **THEN** the building displays that civilization and owner with its architectural style
- **AND** no freestanding identity board blocks the settlement view
