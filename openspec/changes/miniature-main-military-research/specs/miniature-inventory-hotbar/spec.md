## Purpose

Provide direct item, building and army access through the miniature game's reference inventory layout.

## ADDED Requirements

### Requirement: Dedicated hotbar tools

The hotbar SHALL reserve slot 1 for Inventory, slot 2 for the Destroy Hammer and slot 3 for researched Army Control. Keyboard and visible buttons SHALL trigger the same guarded actions without interfering with typing or movement.

#### Scenario: Select a tool

- **WHEN** a player activates slot 1 or slot 2
- **THEN** the item grid opens or the hammer is selected respectively
- **AND** slot 3 becomes actionable only after Army Control completes

### Requirement: Image item grid

The inventory SHALL display held buildings and goods in a scrollable image grid with a bottom-right stack count. Selecting a held building SHALL start its existing placement flow; the hammer SHALL return a legally reclaimed building to this inventory.

#### Scenario: Reclaim and place

- **WHEN** a player reclaims an owned building and selects its grid entry
- **THEN** the returned item count is visible and legal placement consumes one copy
- **AND** research and army-group progress remain intact except removal of the reclaimed building ID
