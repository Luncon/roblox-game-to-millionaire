# Troop recovery

## Purpose

Let hospital-owning armies restore live troop health by returning to their own training yard, without offline gains, revival or changes to existing combat protection.

## ADDED Requirements

### Requirement: Hospital-gated yard recovery
Living damaged owned troops SHALL recover only when their active civilization owns both Hospital I and Training Yard I and they are physically inside that civilization's training yard. This SHALL include the hospital medic and work independently of whether a medic is alive. Players, enemies, neutral actors and passive workers SHALL be excluded.

#### Scenario: Hospital is absent
- **WHEN** wounded troops regroup inside an owned training yard without Hospital I
- **THEN** the existing camp rest behavior continues without restoring health

#### Scenario: Medic is waiting to respawn
- **WHEN** owned wounded fighters reach their hospital-enabled yard while the medic is dead
- **THEN** those fighters can recover without waiting for the medic replacement

### Requirement: Continuous safe presence
A troop SHALL remain inside the yard and free from damage for two continuous active seconds before recovery begins. Each subsequent healing tick SHALL restore five health at most once per second. Eligibility SHALL be checked in the current plot frame with a bounded vertical tolerance; leaving, damage or lost authority SHALL reset the wait.

#### Scenario: Crossing the yard or standing above it
- **WHEN** a wounded troop briefly crosses the yard or remains high above its physical floor
- **THEN** it receives no recovery until it satisfies continuous grounded presence

#### Scenario: Recovery after arrival
- **WHEN** an eligible wounded troop has spent two uninterrupted seconds inside the yard
- **THEN** its first five-health recovery tick is allowed and further ticks occur at most once per second

### Requirement: Order-compatible recovery
Recovery SHALL depend on actual presence and eligibility rather than an order label. Regroup SHALL continue guiding all troops into the yard and preserving their bounded resting movement. Hold SHALL permit recovery while stationary inside the yard. Advance SHALL stop yard recovery immediately when the troop leaves.

#### Scenario: Hold inside and outside the yard
- **WHEN** Hold is active for one eligible wounded troop inside its owned yard and another outside
- **THEN** the inside troop can recover after the wait while the outside troop cannot
- **AND** in-range fighter attacks and medic bandages continue according to their separate command rules

### Requirement: Bounded live health
Recovery SHALL clamp to the troop's current maximum health, never revive a dead life, and never alter maximum health, gear, cooldowns, coins, troop capacity or replacement timers. Bandages and yard ticks SHALL share the same health bounds even when they resolve during the same frame.

#### Scenario: Simultaneous healing near full health
- **WHEN** a bandage and yard tick resolve for a troop missing fewer than five health
- **THEN** combined healing reaches at most its current maximum health
- **AND** no rewards, attack effects or extra deployment occur

### Requirement: No banked or stale recovery
Recovery clocks SHALL be transient and isolated by troop life, owner and civilization. They SHALL accrue no offline, inactive-civilization, full-health or non-writable time. A stalled update SHALL NOT replay missed healing ticks. Death, departure, switch, hospital loss or world teardown SHALL discard pending recovery.

#### Scenario: Rejoin or resume after a pause
- **WHEN** an owner rejoins, switches back, regains authority or resumes after a stalled update
- **THEN** no historical healing is applied
- **AND** each currently eligible troop must satisfy the current live wait without changing any respawn deadline

### Requirement: Clear recovery presentation
Hospital and training-yard presentation SHALL explain that the hospital unlocks troop recovery at the yard. Actual recovering troops SHALL visibly reflect health changes, and full-health troops SHALL stop displaying an active recovery state.

#### Scenario: Reach full health at rest
- **WHEN** a recovering troop reaches its maximum health
- **THEN** the active recovery indication ends and ordinary camp resting continues
