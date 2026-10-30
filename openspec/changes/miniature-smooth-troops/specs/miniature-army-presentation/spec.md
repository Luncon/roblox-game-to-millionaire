# Spec Delta

## Purpose

Makes original miniature army movement and joint poses appear continuous while
keeping the server responsible for all gameplay decisions and life identities.

## ADDED Requirements

### Requirement: Faster commander travel

The normal-sized commander SHALL walk at32studs/second, twice the previous
16studs/second, on initial spawn and respawn. Native player controls SHALL
remain responsible for input; troop movement SHALL retain its separate tuning.

#### Scenario: Commander spawns

- **WHEN** a commander starts or respawns in the miniature sandbox
- **THEN** the server sets walking speed to32studs/second
- **AND** ordinary movement input walks through the map at that speed

### Requirement: Continuous original troop presentation

Clients SHALL interpolate original server-authored troop positions and joint poses
on rendered frames. Equipment SHALL preserve its attachment relationships and
posed soles SHALL remain on actual supports. Visual interpolation SHALL NOT
change attack, healing, targeting or capture authority.

#### Scenario: Walking between combat updates

- **WHEN** two successive server poses describe a living troop moving
- **THEN** rendered frames between them show intermediate positions and joint poses
- **AND** a native measurement distinguishes server update jumps from rendered movement
- **AND** model identity, clothing, weapons and grips match the original troop

### Requirement: Bounded presentation lifecycle

Presentation SHALL use bounded pose history, reject obsolete samples and avoid
unbounded movement after updates stop. Death, replacement and teardown SHALL
remove stale visuals. Only one troop body and health display SHALL be visible
per current life, with source visibility restored when local rendering stops.

#### Scenario: An old life receives a late sample

- **WHEN** an actor is destroyed or replaced and its old pose arrives later
- **THEN** that pose cannot move the replacement or restore the dead actor
- **AND** ending local rendering restores surviving source visibility and displays

#### Scenario: Server updates are interrupted

- **WHEN** no new poses arrive after the latest known sample
- **THEN** the visual stops at a bounded known position
- **AND** pose history and local instances do not grow without limit

#### Scenario: Faces stay attached during movement

- **WHEN** a troop is drawn through its smoothed local copy
- **THEN** source face decals and textures are hidden alongside source body parts
- **AND** the visible face remains attached to the smoothed head
- **AND** late source decals are also hidden and original local visibility is restored on cleanup
