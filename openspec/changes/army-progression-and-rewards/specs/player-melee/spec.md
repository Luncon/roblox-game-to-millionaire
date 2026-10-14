# Player Melee

## Purpose

Let players fight beside their troops using civilization equipment while keeping damage and reward decisions on the server.

## ADDED Requirements

### Requirement: Equipped melee attack
A living claimed player SHALL activate its equipped civilization weapon to attempt a melee attack. The server SHALL select at most one nearby hostile target in front, enforce reach and cooldown, and derive damage from the owner's current weapon tier.

#### Scenario: Strike a nearby enemy
- **WHEN** an equipped player attacks a visible hostile actor within five studs in front
- **THEN** the enemy takes the player's weapon-tier damage at most once per cooldown

### Requirement: Protected and authoritative attacks
Both actors SHALL be inside the arena. Owners, friendly troops, unclaimed players, and actors outside SHALL remain protected. A client SHALL not choose targets, damage, ownership, or reward amounts. Unequipped, dead, stale-character, and distant requests SHALL deal no damage.

#### Scenario: Forge a damage request
- **WHEN** a client sends extra damage or target data or attacks without the equipped weapon
- **THEN** the server ignores supplied combat values and rejects any invalid attack
