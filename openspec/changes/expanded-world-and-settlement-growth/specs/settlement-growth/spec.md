## Purpose

Let each civilization grow gradually from a small outpost into a complete themed settlement through fifty saved levels.

## ADDED Requirements

### Requirement: Gradual themed settlement growth
Settlement progression SHALL support levels 1 through 50. Each accepted increment SHALL add a small amount of footprint and lasting visible detail. Finished settlements SHALL express their civilization through architecture, districts and landmarks rather than only enlarging a starter building.

#### Scenario: Consecutive upgrades
- **WHEN** a player upgrades a settlement from any level below 50
- **THEN** its level increases by one, its footprint grows slightly and an additional themed feature becomes visible without removing earlier unlocked details

#### Scenario: Completed settlement
- **WHEN** a civilization reaches level 50
- **THEN** its complete settlement fits inside the assigned plot and further settlement purchases are rejected without charging coins

### Requirement: Reachable floor progression
Coin earning and separate settlement, weapon, armor and barracks purchases SHALL remain physical ground controls. Growth SHALL preserve player spawn, equipment access, barracks deployment and clear exits. Currency and all purchases SHALL remain server-authoritative.

#### Scenario: Upgrade during settlement growth
- **WHEN** the settlement expands or a gear tier unlocks
- **THEN** the appropriate floor control shows its actual cost or settlement requirement and remains reachable without adding purchase buttons to the HUD

### Requirement: Preserve saved civilization progress
Existing profile coins and numeric upgrade levels SHALL be retained. Restoration and civilization switching SHALL recreate the correct settlement and equipment under the new progression. Malformed or unsupported data SHALL still block unsafe loading rather than reset progress.

#### Scenario: Existing four-level save
- **WHEN** a player loads previously saved level-four progress
- **THEN** its coins and saved level numbers remain unchanged and the new level-four visuals and balance apply

#### Scenario: Finished saved civilization
- **WHEN** a player switches back to or rejoins a saved level-50 civilization
- **THEN** its completed settlement, gear and current barracks capacity are restored independently of other civilizations
