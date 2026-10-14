# Barracks

## Purpose

Turn the second settlement stage into a small automatic army deployment with
one civilization warrior and an understandable replacement timer.

## ADDED Requirements

### Requirement: Settlement unlock and single unit

A level-one barracks SHALL appear at settlement level 2 and remain available
at later settlement stages. It SHALL automatically deploy one warrior on unlock
and allow at most one living warrior per owner. Deployment SHALL be free.

#### Scenario: Upgrade an outpost
- **WHEN** an owner upgrades from settlement level 1 to 2
- **THEN** a themed barracks appears and one warrior deploys
- **AND** later upgrades or repeated eligibility checks create no extra warrior

### Requirement: Automatic fifteen-second replacement

A dead warrior SHALL be replaced automatically 15 seconds after death while its
owner remains eligible and connected. No replacement SHALL appear early. Leaving
SHALL remove owned units and cancel pending replacements.

#### Scenario: Replace a fallen warrior
- **WHEN** an owner's warrior dies
- **THEN** the owner sees a countdown and has no living warrior for 15 seconds
- **AND** one replacement spawns after the deadline without input or payment

#### Scenario: Owner leaves during countdown
- **WHEN** the owner leaves before replacement
- **THEN** the old replacement is canceled and cannot appear for a new plot owner

### Requirement: Independent army lifecycle

Player character resets SHALL preserve a living warrior and its pending
replacement deadline. Settlement rebuilds SHALL preserve army state and keep
barracks spawns aligned with the current plot transform.

#### Scenario: Reset while a warrior is alive
- **WHEN** an owner resets their character or expands their settlement
- **THEN** the same living warrior remains and no additional unit is deployed

### Requirement: Visible barracks status

The settlement and owner HUD SHALL identify the level-one barracks, warrior
availability, and replacement countdown. Barracks placement SHALL preserve
existing tycoon pad access and settlement bounds.

#### Scenario: View a pending reinforcement
- **WHEN** the owner's barracks is waiting to replace a fallen warrior
- **THEN** the HUD shows its remaining wait and the barracks stays visible
