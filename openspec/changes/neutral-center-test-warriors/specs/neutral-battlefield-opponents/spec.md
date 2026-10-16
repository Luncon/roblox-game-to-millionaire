# Spec Delta

## Purpose

Provide shared, repeatable neutral opponents for testing player and army combat without another connected player.

## ADDED Requirements

### Requirement: Three generic center opponents
When test opposition is enabled, the server SHALL maintain two generic melee slots and one generic ranged slot near the battlefield center, independent of player claims. Opponents SHALL have neutral labels and basic equipment. Disabling opposition SHALL prevent their creation.

#### Scenario: Solo battlefield has opponents
- **WHEN** the prototype starts with test opposition enabled and one player joins
- **THEN** two neutral melee fighters and one neutral ranged fighter exist near the center without occupying a civilization or settlement slot

#### Scenario: Opposition is disabled
- **WHEN** the prototype starts with test opposition disabled
- **THEN** no neutral test opponents spawn

### Requirement: Neutral faction combat
Every claimed civilization's players and troops SHALL be able to attack neutral opponents through the normal server combat path. Neutral opponents SHALL fight claimed players and troops, but SHALL NOT fight one another. Arena, range, line-of-sight, cooldown, friendly-owner and unclaimed-player protections SHALL remain enforced.

#### Scenario: All civilizations can fight neutral enemies
- **WHEN** a player or troop from any of the thirteen civilizations makes a valid attack on a neutral opponent
- **THEN** the attack deals the normal attacker damage regardless of civilization

#### Scenario: Neutral combat respects protection
- **WHEN** a neutral opponent attempts to damage another neutral, an unclaimed player or an actor outside the battlefield
- **THEN** the attempt deals no damage

### Requirement: Basic autonomous opponents
Neutral opponents SHALL use 100 maximum health and level-one combat values: melee damage 10 with five-stud reach and one-second cooldown, ranged damage 8 with 45-stud reach and two-second cooldown. Ranged attacks SHALL use validated visible projectiles. Opponents SHALL pursue eligible nearby targets inside the arena and return toward their center positions when idle.

#### Scenario: Melee and ranged enemies fight back
- **WHEN** a claimed hostile actor approaches the neutral enemies inside the arena
- **THEN** melee enemies approach to strike and the ranged enemy fires projectiles when a valid target is within range

### Requirement: Independent ten-second respawns
Each dead neutral opponent SHALL receive one replacement of the same class at its center spawn after ten seconds, never earlier. Other slots SHALL retain their living fighters and existing deadlines. Replacement health SHALL be full. Death and destruction callbacks SHALL NOT create duplicate replacements.

#### Scenario: Staggered deaths preserve separate timers
- **WHEN** a melee enemy dies and the ranged enemy dies three seconds later
- **THEN** the melee slot replaces after its own ten-second delay and the ranged slot replaces three seconds afterward while the remaining melee enemy stays alive

### Requirement: Normal kill credit without neutral progression
A valid player or owned-troop final hit against a neutral opponent SHALL award the existing ten-coin reward at most once per life, subject to writable-profile checks. Neutral opponents SHALL have no saved profile, earn no rewards and remain independent of player gear, orders and civilization switches.

#### Scenario: Player receives one normal reward
- **WHEN** a player or owned troop kills a neutral opponent with a valid writable active profile
- **THEN** that civilization receives ten coins once and no neutral profile is created

#### Scenario: Player changes civilization
- **WHEN** a player switches civilization or upgrades equipment while a neutral slot awaits replacement
- **THEN** the neutral slot keeps its class, basic stats and existing respawn deadline

### Requirement: World lifecycle cleanup
Stopping the neutral service or removing the generated world SHALL remove its actors, corpses and projectiles and cancel pending replacement work without touching unrelated developer geometry or source assets.

#### Scenario: Shutdown during a respawn wait
- **WHEN** the world is removed while an opponent has a pending replacement
- **THEN** the opponent never respawns and its remaining combat resources are cleaned up
