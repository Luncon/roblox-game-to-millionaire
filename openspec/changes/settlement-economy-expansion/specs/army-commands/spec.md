## Purpose

Improve reinforcement pacing as settlements grow while retaining commanded troop slots, gradual combat statistics and independent replacement timers.

## ADDED Requirements

### Requirement: Later barracks speed tiers
Barracks V SHALL unlock at settlement 8, cost 200 coins and set future respawn waits to 13 seconds. Barracks VI SHALL unlock at settlement 14, cost 300 coins and set future waits to 12.5 seconds. These tiers SHALL retain two barracks slots and the existing optional camp slot, without changing damage or health.

#### Scenario: Unlock the next respawn purchase
- **WHEN** an owner with Barracks IV advances from settlement 7 to 8
- **THEN** the Barracks V floor pad appears at the barracks
- **AND** Barracks VI remains hidden until V is owned and settlement 14 is reached

### Requirement: Existing army state survives speed purchases
Buying a later barracks tier SHALL preserve living troop identities, health, classes, orders and pending replacement deadlines. New deaths SHALL use the newly purchased delay. Selected camp classes and independent replacement behavior SHALL continue to work with tiers V and VI.

#### Scenario: Purchase while a troop is dead
- **WHEN** an owner buys Barracks VI while a V-era replacement is pending
- **THEN** that pending deadline remains unchanged
- **AND** its replacement obeys the current order and later deaths wait 12.5 seconds
