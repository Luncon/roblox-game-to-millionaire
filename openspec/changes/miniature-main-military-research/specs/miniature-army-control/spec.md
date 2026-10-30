## Purpose

Let players select which building-owned troops deploy while keeping one dependable all-army command.

## ADDED Requirements

### Requirement: Research-unlocked army groups

Army Control research SHALL unlock a control panel with Army 1 containing all troops and one editable group. Each subsequent control tier SHALL unlock one additional group, up to four total. Custom groups SHALL contain only owned military building IDs, with no duplicates or overlapping assignments.

#### Scenario: Edit an army

- **WHEN** a player edits an unlocked custom army and selects owned military structures
- **THEN** the saved selection changes only after a valid server request
- **AND** Army 1 remains all troops and troops retain their lives, health and orders
- **AND** reclaiming a structure removes it from saved groups

### Requirement: Explicit army deployment

After Army Control unlocks, E at a capturable outpost SHALL open an army deploy chooser. The server SHALL validate the living owner, civilization, authority, unlocked group and proximity before assigning that army's structures to the outpost. Without Army Control, E SHALL retain the existing whole-army command.

#### Scenario: Deploy a custom army

- **WHEN** a nearby player deploys an unlocked nonempty group
- **THEN** only that group's building troops and future replacements receive the target
- **AND** other armies retain their targets
- **AND** deploying Army 1 clears custom target overrides

### Requirement: Saved groups and transient orders

Group membership SHALL save independently per player and civilization. Targets SHALL remain session-only and clear on claim loss or civilization changes. Hidden panels SHALL continue context and proximity guards without sending gameplay requests.

#### Scenario: Switch civilization

- **WHEN** a player switches away and returns
- **THEN** valid saved group membership restores but old deployment targets do not
