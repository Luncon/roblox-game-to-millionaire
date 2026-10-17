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

### Requirement: Patient-first advance and retreat
During Advance a medic SHALL prioritize wounded owned troops with safe visible healing positions. With no patient it SHALL fall back behind living fighters. Nearby hostiles SHALL trigger grounded avoidance. Supported retreat bursts SHALL remain bounded; isolated medics SHALL withdraw toward reinforcements. Movement SHALL respect terrain and obstacles without teleporting or pursuing enemies.

#### Scenario: No troop needs healing
- **WHEN** no owned patient can be helped
- **THEN** the medic falls back approximately 12 studs behind living fighters
- **AND** an unavailable backline position uses its safe owner-side rally

#### Scenario: A replacement is still returning
- **WHEN** a healthy replacement is far behind while an owned fighter needs healing near the battlefield
- **THEN** the medic helps or approaches the wounded fighter rather than moving toward the averaged army position
- **AND** it re-evaluates patients when a life dies, is replaced or reaches full health

#### Scenario: A patient is beyond bandage range
- **WHEN** an owned wounded troop is beyond 45 studs and a grounded visible healing position can be reached safely
- **THEN** the medic approaches healing range without requiring a position behind every troop
- **AND** it rejects healing endpoints within 18 studs of hostiles and approach legs passing within 12 studs of hostiles

#### Scenario: A hostile approaches the healer
- **WHEN** a hostile comes within 12 studs of an advancing medic
- **THEN** it interrupts any unlaunched throw and chooses a safe retreat toward at least 18 studs of separation when available
- **AND** it resumes patient support or its backline fallback after the threat clears without resetting its healing cooldown

#### Scenario: Fighters are absent
- **WHEN** no owned fighter remains within 100 studs during Advance
- **THEN** the medic continuously withdraws toward its nearest current fighter or its own barracks waiting area if all fighters are dead
- **AND** it rejoins when a fighter is within 35 studs, without stopping after a three-second supported retreat burst
- **AND** it does not move to enemies or enter another settlement seeking patients

### Requirement: Critical fighter recovery
During Advance an owned melee or ranged fighter at or below 25% health SHALL withdraw toward a living owned medic's healing range and pause offensive actions until reaching 60% health. This SHALL preserve pending respawn and attack/skill cooldown deadlines. Hold SHALL remain stationary, and Regroup SHALL retain yard return. Missing medics, lost authority and new lives SHALL invalidate stale recovery state.

#### Scenario: Withdraw and recover
- **WHEN** a fighter becomes critically wounded and its owner has a living hospital medic
- **THEN** it cancels pending attacks, skills and shots and seeks a clear position within 20 studs of the medic
- **AND** healing to 60% releases its temporary recovery state without changing the army's order

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
Each bandage SHALL visibly travel toward a selected patient and restore up to 12 health to one nearest eligible troop within three studs of its swept path. A medic SHALL have at most one pending bandage, a three-second launch cooldown and 45-stud source range. Walls SHALL block proximity healing. Only troop lives registered to that owner/civilization at launch SHALL be eligible; expired or distant misses SHALL heal nobody.

#### Scenario: A patient moves or a wall intervenes
- **WHEN** a moving patient passes within three studs of a bandage
- **THEN** the nearest eligible wounded troop receives one clamped heal even without a direct body hit
- **AND** troops farther away, behind walls, foreign owners and replacement lives receive no healing

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
