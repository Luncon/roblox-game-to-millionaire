# Spec Delta

## Purpose

Shows physical cosmetic collapse when miniature troops and mounted animals die, while keeping combat authority and replacement lifecycles separate from corpses.

## ADDED Requirements

### Requirement: Confirmed death creates a physical ragdoll

Confirmed current-life deaths of owned or neutral melee, ranged, medic and mounted troops SHALL create cosmetic physical ragdolls. Mounted animals and riders SHALL collapse with articulated limbs and attached equipment. Client presentation SHALL NOT cause damage, ownership changes or capture occupancy.

#### Scenario: A mounted troop dies in combat

- **WHEN** the server confirms a mounted life has died
- **THEN** its animal and rider physically collapse from their latest visible pose
- **AND** they cease combat immediately while equipment remains attached
- **AND** the existing building-owned respawn deadline continues unchanged

#### Scenario: A regular or neutral troop dies

- **WHEN** a current melee, ranged or medic life dies
- **THEN** a physical ragdoll appears for that life with its appearance preserved
- **AND** the dead life cannot attack, heal or contribute to capture

### Requirement: Removal and stale lives do not imply death

Building reclaim, civilization switching, authority loss, scene cleanup and ordinary removal SHALL NOT create death ragdolls. Duplicate death observations SHALL produce at most one corpse per life. A corpse SHALL NOT remove or alter a replacement life.

#### Scenario: A facility is reclaimed

- **WHEN** its living troop disappears through the destroy hammer
- **THEN** no corpse is created and its visual is cleaned up normally

#### Scenario: A replacement arrives while a corpse remains

- **WHEN** a new life occupies the same building slot
- **THEN** the living troop renders normally and old-life corpse cleanup leaves it unchanged

### Requirement: Cosmetic physics and cleanup are bounded

Corpses SHALL collide with ground without blocking commanders, selection or combat queries. Corpse duration and active physical geometry SHALL have fixed bounds. Ending the renderer or removing its scene SHALL clean up owned corpse models, attachments, constraints and connections.

#### Scenario: Repeated deaths exceed the presentation budget

- **WHEN** combat produces more corpses than the configured limit
- **THEN** older cosmetic corpses are retired before exceeding that limit
- **AND** all corpses expire after a short lifetime without affecting server gameplay
