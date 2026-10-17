# Medic support

## Purpose

Provide a non-offensive hospital troop that supports wounded owned fighters with visible ranged healing while respecting army orders and safe backline movement.

## ADDED Requirements

### Requirement: Hospital medic lifecycle
An owned Hospital I SHALL automatically deploy one medic at a safe hospital exit. Death SHALL schedule only that slot's replacement after 15 seconds. Barracks upgrades SHALL NOT change medic delays. Purchases SHALL preserve an existing medic life, missing health, healing cooldown and pending replacement. New medics SHALL obey the current army order.

#### Scenario: Only the medic dies
- **WHEN** the hospital medic dies while the other three troop slots are alive
- **THEN** those fighters and their timers remain unchanged
- **AND** one medic replacement appears from the hospital after its independent wait

#### Scenario: Purchase during a medic wait
- **WHEN** weapon, armor, barracks or another building is purchased during a pending medic replacement
- **THEN** that replacement deadline remains unchanged

### Requirement: Non-offensive targetable class
Medics SHALL be valid enemy attack targets with the owner's current armor health and civilization appearance. They SHALL deal no ordinary, projectile or weapon-skill damage. Weapon upgrades SHALL NOT increase bandage healing. They SHALL have recognizable bandage equipment and throw poses without mutating imported source assets.

#### Scenario: Attack a medic
- **WHEN** an enemy attacks a medic within the existing combat protection and range rules
- **THEN** normal damage and the existing exactly-once final-hit reward rules apply
- **AND** the medic does not retaliate or activate a weapon-family skill

### Requirement: Backline advance and retreat
During Advance a medic SHALL follow a safe position approximately 12 studs behind its living fighters. Nearby hostile threats SHALL take priority over healing and trigger bounded, grounded retreat. It SHALL avoid crossing fighter fronts to pursue patients, respect terrain and obstacles, and never teleport, flee indefinitely or pursue enemies.

#### Scenario: A hostile approaches the healer
- **WHEN** a hostile comes within 12 studs of an advancing medic
- **THEN** it interrupts any unlaunched throw and chooses a safe retreat toward at least 18 studs of separation when available
- **AND** it resumes backline support after the threat clears without resetting its healing cooldown

#### Scenario: Fighters are absent
- **WHEN** no living owned fighter can anchor the backline
- **THEN** the medic waits at a safe owner-side support rally or retreats from nearby threats
- **AND** it does not move to enemies or enter another settlement seeking patients

### Requirement: Stationary Hold support
Hold SHALL stop all owned troop movement. Fighters SHALL retain their existing attacks against enemies already within valid attack range. The medic SHALL continue throwing bandages to valid patients already within healing range, without chasing patients, repositioning or pursuing enemies.

#### Scenario: Hold with enemies and wounded fighters nearby
- **WHEN** Hold is ordered with an attackable enemy and an injured owned fighter in range
- **THEN** fighters attack and the medic heals while every troop remains stationary
- **AND** out-of-range enemies and patients do not cause pursuit

### Requirement: Regroup support
Regroup SHALL cancel pending medical throws and in-flight bandages and return the medic to a distinct arrival/rest position inside its owner's training yard alongside the fighters. New field bandages SHALL pause during Regroup; hospital-enabled yard recovery SHALL remain available. Advance or Hold SHALL resume support without refreshing cooldowns.

#### Scenario: Regroup during a bandage flight
- **WHEN** Regroup is issued before a bandage resolves
- **THEN** that bandage cannot heal after cancellation and the medic returns to its own yard
- **AND** existing fighter regrouping and safe camp wandering remain intact

### Requirement: Owned wounded patient selection
A medic SHALL select a living damaged NPC troop belonging to the same owner and active civilization. It SHALL prioritize the lowest health fraction, then health deficit and proximity with stable ties. Self, players, enemies, neutral opponents, passive workers, full-health actors and obsolete lives SHALL be excluded.

#### Scenario: Mixed nearby actors
- **WHEN** a medic sees wounded owned fighters beside enemies, players and passive farmers
- **THEN** only an eligible owned troop is selected
- **AND** no ally across a different owner is healed

#### Scenario: A critical patient is blocked
- **WHEN** the lowest-health candidate is obstructed or no longer registered and another wounded owned troop is visible in range
- **THEN** the medic selects the visible current patient according to the same health-priority rules
- **AND** no bandage or cooldown is spent on the invalid candidate

### Requirement: Visible bounded bandages
Each bandage SHALL visibly travel toward one selected patient and restore 12 health on one validated contact, with a three-second launch cooldown and 45-stud range. A medic SHALL have at most one pending bandage. Obstructed or missed throws SHALL expire without healing or retargeting another life.

#### Scenario: A patient moves or a wall intervenes
- **WHEN** a locked patient escapes the bandage path, leaves valid range or becomes obstructed
- **THEN** the throw misses or is blocked
- **AND** it does not heal through the obstacle or transfer to another troop

### Requirement: Server-owned medical contacts
The server SHALL choose patients, trajectories, healing amounts and cooldowns and validate source authority, ownership, range, visibility and both actor lives at contact. Healing SHALL clamp to maximum health, grant no coins or combat procs, and never resurrect. Clients SHALL NOT submit patients, amounts or successful contacts.

#### Scenario: Stale or duplicate healing
- **WHEN** a contact repeats, either actor dies or switches, a patient is replaced, or the owner loses write authority
- **THEN** no duplicate, stale or unauthorized healing occurs
- **AND** replacement troops and unrelated civilizations remain unchanged

### Requirement: Medical army presentation
Army status SHALL separately identify medic count, its hospital origin and its respawn deadline. The medic SHALL contribute to total army count and capacity without being counted as a melee or ranged fighter. Command availability and camp class selection SHALL retain their existing ownership and profile guards.

#### Scenario: Full four-slot army
- **WHEN** all slots are alive and the medic later enters its replacement wait
- **THEN** the HUD changes from four active troops to three and shows the medic's own countdown
- **AND** the melee, ranged and camp counts and class choices remain accurate
