# Civilization Switching

## Purpose

Let players continue or begin available civilizations while retaining independent progress and the server's exclusive civilization and plot ownership rules.

## ADDED Requirements

### Requirement: Atomic civilization switching
A player with a loaded writable profile SHALL be able to switch to an available civilization while retaining the same plot. The old civilization's latest progress SHALL be retained, its troops and combat registrations removed, and the new civilization restored without accepting client progress values.

#### Scenario: Switch away and back
- **WHEN** a player switches from an upgraded Spartan settlement to an unstarted civilization and later returns
- **THEN** the other civilization begins with its own progress and Sparta restores its earlier coins and levels
- **AND** the plot remains owned by the same player with no old troops or stale combat actors

### Requirement: Occupied choices preserve the current civilization
Only one player per civilization SHALL be allowed. A rejected, occupied or invalid switch SHALL preserve the player's current claim, economy, buildings, equipment and army. An identical selection SHALL be idempotent.

#### Scenario: Another player owns the destination
- **WHEN** an owner tries to switch to an occupied civilization
- **THEN** the request fails without releasing the current civilization or deducting currency

### Requirement: Private saved-progress previews
The selector SHALL show the player's own saved progress for each civilization, current selection and server availability. Other players SHALL not receive those saved profile records. Only civilization identifiers and control intents SHALL be accepted from clients.

#### Scenario: Open the civilization selector
- **WHEN** an owner opens the change-civilization control
- **THEN** available civilizations show their own saved or new progression
- **AND** the owner can return to the settlement without changing civilization

### Requirement: Restored army and HUD presentation
Restored level-IV profiles SHALL show current progression, two troop slots and independent replacement countdowns in the existing HUD. Saving status and the change-civilization control SHALL fit desktop and compact viewports. Currency and upgrade purchases SHALL remain physical ground interactions.

#### Scenario: Restore a level-IV civilization
- **WHEN** a saved maximum-tier civilization is selected in a running client
- **THEN** the HUD shows its actual tiers, barracks capacity, save state and independently changing slot countdowns
- **AND** the text and change control remain visible without overlapping in supported desktop and compact layouts
