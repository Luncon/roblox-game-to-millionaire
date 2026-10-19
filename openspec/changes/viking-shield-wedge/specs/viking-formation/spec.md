# Spec Delta

## Purpose

Give Viking players a five-troop offensive wedge that marches together and releases into normal combat at close contact.

## ADDED Requirements

### Requirement: Viking formation progression and selection
Vikings SHALL unlock Shield Training at settlement and armor 15 with Armorer I for 150 coins, and Viking Shield Wedge at settlement 20 for 250 coins after War Council I, shields, Barracks Capacity II and Hospital I. Selection SHALL require the living writable owner near their council and save independently by civilization.

#### Scenario: Buy and select the wedge
- **WHEN** an eligible Viking owner purchases the upgrades and selects the wedge at their council
- **THEN** the server deducts the existing prices, saves Viking Shield Wedge and exposes March Formation

#### Scenario: Reject foreign selection and preserve saves
- **WHEN** a foreign, distant, dead or non-writable owner requests the wedge
- **THEN** selection is rejected without changing balances or another civilization's progress
- **AND** legacy saves still load with no selected formation

### Requirement: Five-life wedge assembly and march
March Formation SHALL require three living melee troops, one axe thrower and one medic in the owned Training Yard. The captured lives SHALL assemble at the road center and march at six studs per second with one shieldman ahead of two diagonal shieldmen and paired supports behind. Replacement lives SHALL NOT silently join.

#### Scenario: Assemble on rotated roads
- **WHEN** the owner commands an eligible squad to march from any plot
- **THEN** all five physically assemble into the pointed wedge before the anchor advances
- **AND** lagging members pause the march until cohesion returns

#### Scenario: Reject incomplete squads
- **WHEN** a required troop is absent, incorrectly classed or outside the Training Yard
- **THEN** March Formation is rejected without changing the current order or troop lives

### Requirement: Wedge releases on valid frontline melee contact
An assembling or marching Viking wedge SHALL release to ordinary Advance when any captured frontline member has a living hostile within normal melee reach, with server-validated arena eligibility, visibility and authority. Contact release SHALL be checked even when cohesion or an attack pauses the march. Ranged opportunities alone SHALL NOT release it.

#### Scenario: Contact releases pursuit
- **WHEN** a valid enemy enters a captured shieldman's ordinary melee reach
- **THEN** formation control clears and surviving troops resume ordinary attacks, axe skills and medic support without replacing lives or resetting cooldowns

#### Scenario: Invalid proximity does not release
- **WHEN** only an ally, a dead or stale life, an occluded enemy, or an enemy outside the battlefield or melee reach is nearby
- **THEN** proximity does not release the wedge

### Requirement: Existing orders casualties and shields remain compatible
The wedge SHALL release to Advance at final destination or frontline casualty unless explicitly held. Hold SHALL preserve stationary attacks and healing, Advance and Regroup SHALL cancel formation control, and support losses SHALL leave the captured frontline intact. Viking shields SHALL use existing two-hit frontal protection and physical rack resupply without stat bonuses or same-life equipment refills.

#### Scenario: Hold survives contact and frontline loss
- **WHEN** the owner holds a wedge and an enemy approaches or a shieldman dies
- **THEN** survivors remain under Hold and may attack or heal without pursuing

#### Scenario: Arrival and casualty restore normal movement
- **WHEN** an unheld wedge reaches its destination or loses a captured shieldman
- **THEN** survivors resume Advance and independent replacement deadlines remain intact

#### Scenario: Spent shields require a rack visit
- **WHEN** a Viking shield blocks two validated frontal hits
- **THEN** it disappears and requires an authorized physical rack pickup to replenish
- **AND** rebuilding equipment alone does not replenish it
