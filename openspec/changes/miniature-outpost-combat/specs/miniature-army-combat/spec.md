# Spec Delta

## Purpose

Turns the miniature settlement's building-owned army into server-controlled
combatants without allowing clients to supply damage, ownership or saved health.

## ADDED Requirements

### Requirement: Building-owned combat army

The system SHALL derive each player's melee, ranged and medic slots from their
placed buildings under the existing ten-troop total. Troop lives and combat
clocks SHALL remain transient and separate from civilian jobs and saved economy.

#### Scenario: Build and reclaim a military structure

- **WHEN** a player places, reclaims or replaces a military building
- **THEN** only its allocated slots join or leave the army
- **AND** unrelated living health, lives and pending replacement deadlines remain unchanged
- **AND** neither building count nor captured outposts increase army capacity

### Requirement: Authoritative attacks and healing

The server SHALL choose movement, hostile targets, damage and cooldowns. Melee
contacts and ranged shots SHALL revalidate living actors, hostility, range and
visibility. Medics SHALL heal only living allied troops and never attack.

#### Scenario: Attack is interrupted or illegal

- **WHEN** an attacker, target life, order, ownership, range or visibility becomes invalid before contact
- **THEN** the pending contact does not damage the former target
- **AND** one legal contact cannot apply damage more than once

#### Scenario: Support heals the army

- **WHEN** an injured living ally is within a medic's legal range and cooldown
- **THEN** the medic restores bounded health without revival or attacking enemies
- **AND** player avatars, civilians and foreign troops receive no healing

### Requirement: Protected homes and noncombatants

The system SHALL exclude home plots, player avatars and civilians from conquest
targets and offensive actor registration. Outpost fighting SHALL remain bounded
away from the protected settlement build areas and future expansion reserves.

#### Scenario: Army receives a home or noncombatant target

- **WHEN** a client requests a home plot as an objective or attempts to supply an arbitrary damage target
- **THEN** the request is refused and no home ownership, health or economy changes

### Requirement: Replacements and fresh authority

Dead allocated troops SHALL respawn from their own structure after a server
deadline. Repeated synchronization SHALL NOT refill health or reset deadlines.
Released, switched or nonwritable civilization armies SHALL stop acting and
lose their transient objectives. Commander death alone SHALL NOT grant troop health.

#### Scenario: Troop replacement and claim loss

- **WHEN** a troop dies while its structure and authority remain valid
- **THEN** its old life cannot attack, heal or occupy an outpost
- **AND** one fresh life returns at its own building after the configured delay
- **WHEN** its building or army authority is removed
- **THEN** no stale life or pending replacement continues combat

### Requirement: Visible combat lives

The system SHALL show moving civilization troops with bounded health bars,
readable melee attacks and visible ranged shots. Rendered clones SHALL preserve
immutable source art and SHALL NOT introduce client-authoritative combat.

#### Scenario: A life is replaced

- **WHEN** an actor dies and later respawns
- **THEN** its dead model disappears and a distinct fresh life is shown at its building
- **AND** source templates and unrelated actors remain unchanged
