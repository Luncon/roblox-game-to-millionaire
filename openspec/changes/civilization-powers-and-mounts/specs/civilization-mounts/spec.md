# Civilization Mounts

Phase two only: retained future contract. Mount implementation, assets and runtime checks are excluded from phase one. Unlocks and numerical mount tuning remain provisional for phase-two review. Civilization-specific specials, elemental effects and ultimates are deferred separately.

## Purpose

Let every civilization summon an owner-controlled animal for travel and battlefield combat with safe riding and lifecycle behavior.

## ADDED Requirements

### Requirement: Complete mount roster and unlock
Each civilization SHALL unlock its themed mount at settlement 10: Sparta horse, Britain horse, Seneca elk, Mongols steppe horse, Vikings reindeer, Persia horse, Japan horse, Maurya elephant, Spain horse, Egypt camel, Rome horse, Ottomans horse and Ming horse. These SHALL be presented as game themes rather than historical claims.

#### Scenario: Elephant and camel
- **WHEN** eligible Mauryan and Egyptian players summon their mounts
- **THEN** they receive distinct animated rideable elephant and camel models respectively
- **AND** all other civilizations also have functional travel and combat mounts

### Requirement: Owner-controlled travel
A writable claimed owner SHALL summon at most one mount at a server-selected clear position in their settlement. Only its owner SHALL ride it. Mounted movement SHALL respect terrain, obstacles, world boundaries and protected foreign plots; it SHALL NOT fly, teleport or fling characters.

#### Scenario: Invalid riding and motion
- **WHEN** another player attempts to board or the rider requests non-finite, excessive or wall-crossing movement
- **THEN** the server rejects the request and preserves a valid mount/rider state

#### Scenario: Dismount safely
- **WHEN** the rider dismounts near terrain or an obstruction
- **THEN** a nearby grounded clear position is chosen
- **AND** if none exists the rider remains mounted with feedback until a safe position is available

### Requirement: Mounted combat
Mounted players SHALL retain validated melee attacks and purchased weapon-family skills and gain a telegraphed animal attack every eight seconds, dealing 75% owner base weapon damage to at most two hostiles within six studs. All combat SHALL require rider and targets inside the unchanged combat band, hostility, visibility and writable authority. Mount attacks SHALL NOT trigger weapon-family skills or their damage multipliers.

#### Scenario: Protected targets
- **WHEN** a rider attacks from outside the battlefield or toward protected or obstructed targets
- **THEN** neither animal nor rider attack deals damage or earns rewards

### Requirement: Health and lifecycle
Mounted combat SHALL use the rider's existing health pool and grant no healing, armor or invulnerability. Hits on the mount SHALL resolve to the rider once per strike. Death, departure, switching or lease loss SHALL remove the mount safely and cancel pending attacks. Summoning SHALL have a 15-second cooldown that survives death and switching within the server.

#### Scenario: Duplicate contact
- **WHEN** one attack overlaps both mount and rider
- **THEN** their shared rider health takes damage once and a lethal result grants at most one kill reward

#### Scenario: Cleanup and progression
- **WHEN** an owner changes civilization with a living mount and pending troop respawns
- **THEN** the mount and its attack disappear without changing troop capacities or respawn deadlines

### Requirement: Controls and saved compatibility
Summon, ride, dismount and animal attack SHALL support keyboard, touch and gamepad with unlock/cooldown feedback. Mount unlock SHALL derive from saved settlement level; position, occupancy, health and cooldown SHALL NOT save or produce offline progress.

#### Scenario: Rejoin
- **WHEN** an eligible player rejoins
- **THEN** their mount remains unlocked but no prior animal instance or battle state is restored
