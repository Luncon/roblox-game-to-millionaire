## Purpose

Provide visible rural economic activity that rewards active play without generating coins for absent players or inactive civilizations.

## ADDED Requirements

### Requirement: Online farm production
An owned Farm I SHALL produce one reserved coin per five seconds while its civilization is active. Worker Camp I SHALL increase production to two coins per five seconds. The initial reserve SHALL hold at most 60 coins and stop production at capacity. Visible passive workers SHALL tend the fields without participating in combat.

#### Scenario: Active income and capacity
- **WHEN** an active Farm I owner without a worker camp plays for ten seconds
- **THEN** two coins accumulate in their reserve without changing their wallet
- **AND** prolonged active play never exceeds 60 reserved coins

### Requirement: Owner collection
The owner SHALL collect reserved coins using a physical farm pad with server-validated ownership, living character and proximity. Collection SHALL transfer each reserved coin once, preserving any amount that cannot fit in the wallet.

#### Scenario: Collection cannot duplicate coins
- **WHEN** an owner collects a reserve of ten coins twice without further production
- **THEN** the wallet increases by ten total and the reserve becomes zero

### Requirement: Safe separate saved farming
Farm and worker levels, reserve and extra troop choice SHALL save per player and civilization. No offline time SHALL produce income. Switching SHALL preserve reserve but discard unearned partial intervals. Lost profile authority SHALL block production, collection and purchases. Legacy valid saves SHALL gain safe zero-building defaults without changing existing balances or levels; malformed supplied new fields SHALL fail validation.

#### Scenario: Switch and reload
- **WHEN** a player switches away from a farm-owning civilization and returns later or rejoins
- **THEN** its saved reserve is restored without income for the intervening time

#### Scenario: Lost writable session
- **WHEN** a player's profile lease is lost
- **THEN** their farm stops producing and collection fails without changing either balance
