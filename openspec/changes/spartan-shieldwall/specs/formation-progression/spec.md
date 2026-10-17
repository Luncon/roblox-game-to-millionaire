## Purpose

Provide paid army growth and faction-specific formation unlocks while preserving independent civilization progress and existing troop lives.

## ADDED Requirements

### Requirement: Universal fifth troop and planning building
Every civilization SHALL offer Army Camp II at settlement 18 for 250 coins after Army Camp I and Barracks VI, adding one dedicated melee slot. War Council I SHALL cost 200 coins at settlement 19 after Training Yard I and provide an accessible map room beside the training yard.

#### Scenario: Expand an existing army
- **WHEN** an eligible owner buys Army Camp II
- **THEN** one additional melee deploys without replacing existing troop lives, health, class choices or pending respawn deadlines

### Requirement: Spartan paid unlocks
Sparta SHALL offer Shield Training I for 150 coins at settlement/armor 15 after Armorer I, and Spartan Shieldwall for 250 coins at settlement 20 after War Council I, shield training and five-slot capacity including the hospital. Other civilizations SHALL NOT purchase these Spartan unlocks. Eligible purchase pads SHALL sit beside the relevant armory or council building.

#### Scenario: Buy formation training
- **WHEN** a Spartan owner meets the dependencies and buys the council-side formation pad
- **THEN** coins are charged once and Shieldwall becomes selectable without granting combat-stat bonuses

### Requirement: Civilization-isolated persistence
Unlocks and formation selection SHALL save per player and civilization under existing version-one keys. Missing new fields SHALL default to locked or unselected; malformed values SHALL be rejected. Live shield charges, health, orders and march phases SHALL NOT persist.

#### Scenario: Restore and switch
- **WHEN** an owner reloads or switches between Sparta and another civilization
- **THEN** each civilization restores only its own progression and selection, and a failed load cannot overwrite prior progress
