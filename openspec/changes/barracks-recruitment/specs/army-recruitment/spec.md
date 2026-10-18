## Purpose

Give owners one clear recruitment location and a saved army composition while preserving purchased progress and troop lives.

## ADDED Requirements

### Requirement: Barracks recruitment progression
The Barracks SHALL own combat capacity at settlement milestones 2, 4, 10 and 18, retaining existing purchase prices and prerequisites. Hospital I SHALL provide a separate medic slot. The maximum SHALL remain four fighters plus one medic. Existing Army Camp purchases SHALL retain their capacity without repayment.

#### Scenario: Restore purchased reinforcements
- **WHEN** an existing owner restores a civilization with Army Camp II
- **THEN** the Barracks supports four combat troops and no replacement capacity purchase is required

### Requirement: Military district layout
The Barracks SHALL stand beside the Training Yard opposite the War Council, with its entrance facing the yard. Its recruitment screen, upgrade pads, spawn points and shield supplies SHALL have clear supported approaches. The separate Army Camp building and its remote upgrade pad SHALL be removed.

#### Scenario: Reach recruitment and training
- **WHEN** a settlement unlocks its Barracks
- **THEN** its owner can walk to the recruitment screen and troops can walk from the Barracks to supplies and camp on every plot

### Requirement: Saved bounded composition
The owner SHALL select nonnegative whole counts of melee, ranged and medics at the owned Barracks screen. Fighter totals SHALL not exceed purchased Barracks capacity; ranged SHALL require Barracks IV and medics SHALL require the Hospital with at most one. Choices SHALL save independently per civilization. Invalid, remote, foreign, dead or unwritable requests SHALL be rejected.

#### Scenario: Save a full formation lineup
- **WHEN** an eligible nearby owner saves three melee, one ranged and one medic
- **THEN** that composition governs future spawns and restores on returning to that civilization

#### Scenario: Exceed capacity or bypass an unlock
- **WHEN** a request asks for too many fighters, locked ranged troops, extra medics or malformed counts
- **THEN** it changes neither the saved composition nor living troops

### Requirement: Spawn continuity
Composition changes SHALL preserve living troop identities, health, classes, shields and cooldowns, and pending respawn deadlines. Disabled slots SHALL stop replacing troops after death. Reenabled slots SHALL respect any pending deadline. Default legacy composition SHALL remain automatic until explicitly selected. Formation muster SHALL still require its actual three melee, archer and medic lives.

#### Scenario: Change an injured fighter's future class
- **WHEN** an owner changes composition while a troop is injured or awaiting replacement
- **THEN** the living troop retains its health and class and the next replacement uses the selected class after the original deadline

### Requirement: Fresh troop shield collection
Newly spawned shield-eligible melee SHALL begin without shields, physically collect one two-hit shield at their owned rack, then follow their army order. Hold SHALL pause this travel. Lost authority SHALL prevent collection. Spent living shields SHALL remain replaceable through Regroup without changing health or cooldowns. Ranged, medics and player avatars SHALL retain their existing equipment rules.

#### Scenario: Equip a fresh shieldman
- **WHEN** a shield-trained owner receives a new melee troop
- **THEN** it walks from the Barracks to supplies, gains its shield only within pickup distance and continues its order

### Requirement: Persian spear orientation
The Persian spear SHALL point toward its attack direction during ordinary thrusts and skills for players and troops. The adjustment SHALL preserve its source template and other civilizations' attachment orientations.

#### Scenario: Thrust with the corrected spear
- **WHEN** a Persian player or troop performs a spear thrust
- **THEN** its spearhead points toward the thrust and the immutable source template remains unchanged

### Requirement: Persian cautious final approach
The Persian Archer Screen SHALL deploy at 30 studs from a valid visible target rather than 40. After its captured archer first has a clear valid target within normal 45-stud bow range, the formation SHALL approach at three studs per second, half its normal six. Other formations SHALL retain their existing speed.

#### Scenario: Close the final distance cautiously
- **WHEN** the Persian archer gains a clear target at 40 studs
- **THEN** the formation continues at half speed until the target is within 30 studs, then deploys
