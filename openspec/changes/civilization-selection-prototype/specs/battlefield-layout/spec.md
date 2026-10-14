# Battlefield layout

## Purpose

Provide an identifiable prototype battlefield with settlement plots so players
can experience the intended circular multiplayer map before final artwork exists.

## ADDED Requirements

### Requirement: Circular eight-plot layout

The prototype SHALL provide one central battlefield, eight numbered settlement
plots evenly spaced around it, and an entry spawn outside the battlefield.

#### Scenario: Begin a fresh playtest

- **WHEN** the server starts the prototype
- **THEN** players can find eight distinct numbered plots surrounding the battlefield
- **AND** an unclaimed player's character spawns at the entry area

### Requirement: Visible settlement ownership

Each plot SHALL display its number and whether it is unclaimed or owned. An
owned plot SHALL display the civilization and owner name and a placeholder settlement.

#### Scenario: Claim and release a settlement

- **WHEN** a player successfully claims a civilization
- **THEN** the assigned plot visibly identifies its civilization and owner
- **AND** leaving the server restores that plot's unclaimed appearance

### Requirement: Preserve the editing workspace

Generated prototype objects SHALL stay inside a dedicated runtime model and
SHALL NOT replace unrelated objects the developer built in Studio.

#### Scenario: Playtest an existing Baseplate

- **WHEN** the prototype starts in a place with existing Workspace objects
- **THEN** those unrelated objects remain intact
- **AND** prototype map objects are grouped separately
