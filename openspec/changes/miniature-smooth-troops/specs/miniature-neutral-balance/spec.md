# Spec Delta

## Purpose

Gives capturable neutral garrisons near-peer combat strength while retaining a
small, explicit disadvantage against the corresponding player troop roles.

## ADDED Requirements

### Requirement: Slight neutral disadvantage

Neutral role health, damage and movement speed SHALL equal95% of the corresponding
player role values. Attack reach, windup, cooldown and recovery SHALL match that
role so the small disadvantage is not compounded by weaker timing or range.

#### Scenario: Matching melee troops fight

- **WHEN** player and neutral melee profiles are compared
- **THEN** neutral health is152against160, damage28.5against30 and speed5.7against6
- **AND** their attack ranges and phase timings match

#### Scenario: Matching ranged troops fight

- **WHEN** player and neutral ranged profiles are compared
- **THEN** neutral health is114against120and damage22.8against24
- **AND** both have ten-stud reach and matching attack timing
- **AND** the original behavior adapter uses these profiles in authoritative combat

### Requirement: Preserve outpost capture conditions

Near-peer balance SHALL retain the first garrison's two melee and one ranged,
neutral replacement deadlines and20clear occupied seconds for capture, pausing
while defenders live. No victory SHALL be guaranteed for an outnumbered force.

#### Scenario: A mixed army captures the first outpost

- **WHEN** a normally purchased and placed mixed army attacks the garrison
- **THEN** server-validated fighting and replacements determine the outcome
- **AND** capture still requires the existing clear occupied time and defender pauses
