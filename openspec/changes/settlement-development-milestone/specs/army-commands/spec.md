## Purpose

Let commanders direct their own troops and choose reinforcements while preserving automatic deployment and fair respawn limits.

## ADDED Requirements

### Requirement: Training yard commands
Buying Training Yard I SHALL unlock advance, hold and regroup controls. The server SHALL allow only the living owner with a writable active profile to issue these orders to their army. Advance SHALL resume autonomous battlefield movement; hold SHALL stop movement and attack only enemies already in range; regroup SHALL return to a server-chosen home rally without pursuing enemies.

#### Scenario: Hold stops pursuit
- **WHEN** an eligible owner issues hold while a troop is pursuing an enemy
- **THEN** the troop stops chasing and does not move to enemies outside attack range

#### Scenario: Invalid commands
- **WHEN** a player without Training Yard I or a writable profile requests an order
- **THEN** no troop order changes

### Requirement: Selectable third slot
Army Camp I SHALL add exactly one reinforcement slot to the original melee and ranged slots. Its owner SHALL select melee or ranged using only unlocked classes. The selected class SHALL save per civilization and take effect at the next spawn without replacing a living troop or resetting a pending respawn.

#### Scenario: Change while troop is alive
- **WHEN** an owner changes the camp class from melee to ranged while its melee troop lives
- **THEN** that troop keeps its health and class until death
- **AND** the next camp replacement is ranged after the normal respawn delay

### Requirement: Independent army lifecycle
All three slots SHALL receive current civilization gear and server ownership, independent death timers and shared final-hit rewards. New replacements SHALL obey the current army order. Switching civilizations or leaving SHALL destroy all owned troops and pending deployment work.

#### Scenario: Independent reinforcements
- **WHEN** only the camp troop dies
- **THEN** the original melee and ranged units remain unchanged and only one camp replacement deploys
