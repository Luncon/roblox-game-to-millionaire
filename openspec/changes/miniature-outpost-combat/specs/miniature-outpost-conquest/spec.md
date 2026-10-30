# Spec Delta

## Purpose

Provides neutral, capturable miniature army objectives between protected player
settlements and the map center, with visible ownership and server-timed capture.

## ADDED Requirements

### Requirement: First outpost on every settlement line

The prototype SHALL place one capturable outpost directly inward from each of
the eight home plots, outside home expansion reserves. Every outpost SHALL start
neutral with two melee defenders and one ranged defender. Deeper tiers SHALL
remain future content, with an ordered line relationship available for progression.

#### Scenario: New sandbox server

- **WHEN** the isolated server starts
- **THEN** eight neutral outposts appear in front of their corresponding home plots
- **AND** each has precisely two melee and one ranged neutral slot
- **AND** home plots are absent from the capturable objective registry

### Requirement: Automatic advance and explicit army targeting

An army SHALL automatically target the first enemy or neutral objective on its
own line and advance to the next after capture when one exists. At the end it
SHALL defend the captured objective. A valid E interaction at any outpost center
SHALL redirect the owner's entire army, including later replacements, to that outpost.

#### Scenario: Automatic and manual objectives

- **WHEN** military buildings produce an army without a manual order
- **THEN** its troops march toward the outpost directly ahead of its home
- **WHEN** the owner presses E near another outpost center
- **THEN** all current and future allocated troops use the new objective
- **AND** pressing E does not teleport troops or grant damage or ownership

### Requirement: Defended occupation capture

After defenders are defeated, living attacking troops inside the outpost SHALL
earn twenty seconds of clear occupation. Living defenders or rival forces SHALL
pause progress. No living attacking troops inside SHALL reset progress. Completion
SHALL transfer ownership only when the full clear duration and presence remain valid.

#### Scenario: Returning defenders during capture

- **WHEN** a neutral defender respawns during a partial capture
- **THEN** the progress bar pauses at its current value until defenders are defeated
- **AND** wiping or withdrawing the attacking force resets progress to zero
- **AND** clearing the defenders again resumes a surviving force's progress

#### Scenario: Competing attackers

- **WHEN** multiple hostile armies occupy a neutral or enemy outpost
- **THEN** capture remains contested without crediting two teams simultaneously
- **AND** only one surviving, uncontested force can finish capture

### Requirement: Neutral respawns and player recapture

Neutral defender slots SHALL respawn at the neutral outpost after server deadlines,
including during capture. Capture SHALL stop neutral respawns without granting
free allied troops. Player-owned outposts SHALL remain capturable by another army
after its defenders are defeated and the same occupation requirement is met.

#### Scenario: Ownership changes

- **WHEN** an army completes capture
- **THEN** the neutral respawn queue stops and the victor's civilization flag flies
- **WHEN** a rival later completes the same capture conditions
- **THEN** ownership and flag switch to the rival without changing either army's cap

### Requirement: Visible capture status

An outpost SHALL display a readable overhead progress bar during capture, identify
its owner and distinguish defending, capturing, contested and paused states. The
display SHALL reflect server state and SHALL NOT require a separate management page.

#### Scenario: Occupation is paused

- **WHEN** defenders return or a rival contests a partial capture
- **THEN** the bar preserves its credited value and visibly reports the interruption

### Requirement: Guarded orders and transient conquest

An army order SHALL require a living nearby commander, current owned writable
civilization, bounded valid outpost ID and fresh session/revision. Ownership,
capture clocks and army orders SHALL remain server-session state. Released or
nonwritable armies SHALL stop acting and their outposts SHALL return to neutral.

#### Scenario: Invalid or replayed order

- **WHEN** a dead, distant, foreign, stale or read-only caller sends a target intent
- **THEN** the server refuses without moving troops or changing ownership
- **AND** a successful replay cannot apply an order twice
- **AND** home IDs, client damage values and client progress values are refused
