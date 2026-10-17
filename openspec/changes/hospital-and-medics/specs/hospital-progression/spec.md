# Hospital progression

## Purpose

Give each civilization an independently saved rear hospital that unlocks a dedicated medic and recovery for its owned army.

## ADDED Requirements

### Requirement: Hospital purchase
Hospital I SHALL cost 200 coins and require settlement level 10 and purchased Training Yard I. Its physical purchase control SHALL validate ownership, claim, distance, funds and writable progress on the server. Army Camp ownership SHALL NOT be required. Locked and completed hospital controls SHALL be absent.

#### Scenario: Buy the hospital once
- **WHEN** an eligible owner uses the hospital purchase control
- **THEN** exactly 200 coins are charged and the hospital is built immediately
- **AND** duplicate interaction cannot charge again or create a second medic slot

#### Scenario: Reject an ineligible buyer
- **WHEN** a foreign, distant, under-level, under-funded or non-writable player attempts construction
- **THEN** no coins, hospital level or troop slots change

### Requirement: Stable rear hospital
The hospital, entrance and purchase standing area SHALL sit behind the settlement, outside its final level-50 foundation and the battlefield. They SHALL remain grounded, reachable and clear of other buildings, fields, entry geometry and neighboring plots through all settlement levels and world transforms.

#### Scenario: Settlement growth and transformed maps
- **WHEN** a hospital-owning settlement grows to level 50 or the generated map is translated or rotated
- **THEN** its hospital stays behind that settlement with clear access and a grounded entrance
- **AND** the landscape remains within 2,000 static BaseParts and settlement geometry remains within its existing 400-part limit

### Requirement: Separate medical deployment capacity
Hospital I SHALL add one dedicated medic slot independently of barracks and Army Camp slots. All other troop capacities and Army Camp class choices SHALL remain unchanged. The maximum army with two barracks slots, Army Camp I and Hospital I SHALL be four troops.

#### Scenario: Hospital without an army camp
- **WHEN** an owner builds a hospital without owning Army Camp I
- **THEN** exactly one medic slot is added alongside the existing barracks slots
- **AND** no camp slot or new camp class choice is granted

### Requirement: Independent saved ownership
The hospital level SHALL save separately for each player and civilization. Only an absent hospital field SHALL default to zero. Invalid supplied levels or prerequisites SHALL fail safe loading. Version-one keys/scopes and all fifteen existing saved fields SHALL remain intact; live medical state SHALL NOT be saved.

#### Scenario: Legacy and civilization restoration
- **WHEN** a valid older profile loads, later builds a hospital and switches civilizations or rejoins
- **THEN** its original progress is preserved and only that civilization restores the purchased hospital
- **AND** a failed load cannot overwrite existing data with a fresh profile

### Requirement: Purchase preservation
Building a hospital SHALL preserve living fighters' health, identity, gear, attacks, cooldowns and pending respawn deadlines. It SHALL unlock training-yard recovery without instantly healing existing troops as a purchase side effect.

#### Scenario: Construction during a fighter respawn wait
- **WHEN** the hospital is purchased with wounded fighters and a pending barracks or camp replacement
- **THEN** existing fighter health and the pending deadline remain unchanged
- **AND** the new medic deploys from its own hospital slot
