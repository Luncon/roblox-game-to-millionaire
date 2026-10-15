## Purpose

Give settlement growth useful building purchases and readable physical progression throughout the first ten settlement levels.

## ADDED Requirements

### Requirement: Building unlocks and purchases
The game SHALL offer Training Yard I at settlement 5, Farm I and Worker Camp I at 7, and Army Camp I at 10. Purchases SHALL be immediate, separately saved per civilization and server-priced. Worker Camp I SHALL require Farm I. Army Camp I SHALL require Barracks IV.

#### Scenario: Buy the first economic buildings
- **WHEN** an owner at settlement 7 buys Farm I then Worker Camp I at their respective pads
- **THEN** their coins are charged once per building and both buildings appear immediately
- **AND** another player cannot purchase them for that owner

### Requirement: First settlement milestone
Entering settlement 10 SHALL require Barracks IV, Training Yard I, Farm I and Worker Camp I. The main hall SHALL show missing prerequisites. Existing saves already at or above 10 SHALL retain their settlement level.

#### Scenario: Missing farm blocks a milestone
- **WHEN** a settlement 9 owner has sufficient coins but lacks Farm I
- **THEN** settlement 10 cannot be purchased and the main hall identifies the missing building

### Requirement: Distributed available pads
Upgrade pads SHALL be placed near their corresponding buildings or construction sites. Progression-locked and completed one-time pads SHALL be absent. Unlocked unaffordable pads SHALL remain visible with prices. Main hall, armory, barracks, training yard, farm, worker camp and army camp controls SHALL remain reachable as the settlement grows.

#### Scenario: Unlock construction sites
- **WHEN** an owner advances from settlement 4 to 5
- **THEN** a training-yard purchase pad appears beside its site
- **AND** farm and army-camp pads remain absent

#### Scenario: Weapon cap hides its pad
- **WHEN** weapon level equals settlement level
- **THEN** the next weapon purchase pad is absent until the settlement is upgraded

### Requirement: Stable rural space
Farms SHALL occupy reserved terrain outside the final settlement footprint and battlefield. Rural buildings and crops SHALL leave the central troop approach clear and SHALL use civilization-themed visuals.

#### Scenario: Fully expanded settlement
- **WHEN** a farm-owning civilization reaches settlement 50
- **THEN** its farm remains outside the expanded foundation and its pads and access routes remain usable
