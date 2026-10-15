## Purpose

Provide fifty meaningful weapon and armor tiers with small bounded advantages shared by players and their troops.

## ADDED Requirements

### Requirement: Bounded gradual equipment stats
Weapon and armor tracks SHALL contain 50 levels with strictly increasing linear stats. Melee damage SHALL range from 10 to 18 and standard armor health from 100 to 140; ranged damage SHALL retain its existing class multiplier without dropping fractional improvements.

#### Scenario: Adjacent levels
- **WHEN** a weapon or armor level increases by one
- **THEN** melee damage increases by 8/49 or armor health increases by 40/49, without a compounding multiplier

#### Scenario: Maximum tier combat
- **WHEN** maximum-tier equipment is applied
- **THEN** standard melee damage is 18 and standard max health is 140, and damage remains subject to normal range, ownership and battlefield checks

### Requirement: Settlement-gated separate purchases
Weapon and armor SHALL upgrade independently, one level per accepted purchase, through level 50. Neither track SHALL exceed settlement level. Failed, stale, unaffordable, locked or maximum-level purchases SHALL not charge coins or change progression.

#### Scenario: Settlement level reached
- **WHEN** a track already equals the settlement level
- **THEN** its next purchase is disabled or rejected with a settlement requirement until the settlement grows

### Requirement: Persistent inherited equipment
Players, living troops and replacement troops SHALL use the same owner's saved weapon and armor levels. Armor refresh SHALL preserve missing health without repeated healing, and unlocked themed cosmetics SHALL remain present at higher tiers.

#### Scenario: Refresh a wounded troop
- **WHEN** its owner buys an armor tier or refreshes identical equipment
- **THEN** only the newly added health capacity is granted and repeated identical refreshes do not heal it

#### Scenario: Fractional lethal hit
- **WHEN** a fractional melee or ranged hit kills a hostile actor
- **THEN** the final-hit civilization receives exactly one ten-coin reward
