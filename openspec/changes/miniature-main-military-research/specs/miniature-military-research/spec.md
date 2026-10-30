## Purpose

Give miniature armies civilization-specific research progress and a readable themed military upgrade tree.

## ADDED Requirements

### Requirement: Reference military progression

The game SHALL offer the 29 applicable nodes in the user's 36-row military guide with its prices, durations and prerequisite paths. Vehicle upgrades SHALL affect mounted troops. Modern unlock/missile nodes and civilian research SHALL remain unavailable placeholders. Building purchases SHALL remain research-free.

#### Scenario: Browse research

- **WHEN** a player opens Research
- **THEN** a pannable, zoomable hex tree shows connected military nodes, a grey civilian half and selected-node price, time, effect and prerequisites
- **AND** future nodes cannot be purchased

### Requirement: Authoritative research projects

The server SHALL charge Coins once for an affordable eligible project, allow one active project per civilization, and complete it only after its listed active-play duration. Completed projects and remaining duration SHALL restore independently per player and civilization. Invalid or duplicate requests SHALL leave progress and Coins unchanged.

#### Scenario: Pause and restore

- **WHEN** a player switches civilizations, dies, disconnects or loses write authority during a project
- **THEN** inactive time does not advance research
- **AND** returning to that civilization restores its remaining time without an additional payment

### Requirement: Additive army modifiers

Completed tiers SHALL add damage, maximum health, movement speed and reach to their specified foot or mounted classes without double counting. Capacity upgrades SHALL raise weighted capacity from 10 to 12, 15 and 20; mounts SHALL continue to cost two slots. Foot reach SHALL cover melee, ranged and medic healing.

#### Scenario: Upgrade a living army

- **WHEN** research completes while troops or replacements exist
- **THEN** current lives receive their derived statistics without healing, resetting cooldowns, cancelling contacts or changing pending replacement deadlines
- **AND** fresh troops spawn with their upgraded maximum health
- **AND** launched projectiles retain their launch range

### Requirement: Safe progress upgrade

Existing valid miniature saves SHALL receive missing military fields only. Malformed progress, unknown nodes, broken prerequisite chains and invalid projects SHALL be rejected without overwriting the original profile. Legacy full-size combat defaults SHALL remain unchanged.

#### Scenario: Load older progress

- **WHEN** valid pre-research progress is loaded
- **THEN** the civilization retains its Coins, buildings and goods and starts with no completed military projects
