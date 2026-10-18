## Purpose

Allow quick progression testing in the normal Studio game build using a visible physical coin grant while keeping public-server currency authority unchanged.

## ADDED Requirements

### Requirement: Normal Studio testing pad
The normal Studio build SHALL show a physical +1,000 TEST COINS pad beside each plot's earning pad. A nearby living owner with writable claimed progress SHALL receive exactly 1,000 coins per accepted activation, subject to the existing balance cap and at most one grant per half second. The amount SHALL be chosen by the server and apply only to the active civilization.

#### Scenario: Fund upgrades in the main Studio build
- **WHEN** a living owner clicks or interacts with the nearby testing pad in normal Studio Play
- **THEN** exactly 1,000 coins are added to that civilization and reflected in the HUD without requiring a separate temporary-currency build

### Requirement: Grant environment and authority
Testing pads SHALL be absent outside Studio and grant attempts SHALL be rejected outside Studio even if called directly. Foreign, distant, dead, unclaimed, unwritable, rate-limited or over-cap requests SHALL NOT alter balances. No client-provided amount or generic currency remote SHALL be introduced.

#### Scenario: Reject unauthorized grant
- **WHEN** a foreign or distant player, a failed profile, or a public server attempts a testing grant
- **THEN** no coins or saved progress change
