# Warrior Combat

## ADDED Requirements

### Requirement: Civilization melee warrior

Each civilization SHALL deploy a recognizable themed humanoid warrior with
melee equipment. Warriors SHALL walk from their barracks to the central arena
using navigable routes around settlement obstacles, without teleporting.

#### Scenario: Deploy from an expanded settlement
- **WHEN** a warrior deploys from a settlement with walls
- **THEN** it navigates around obstacles and reaches the central battlefield
- **AND** it uses melee attacks regardless of civilization

### Requirement: Inherit owner equipment upgrades

Warriors SHALL inherit the owner's weapon damage, armor maximum health, and
corresponding themed appearance. Upgrading SHALL update the living unit in
place. Armor changes SHALL preserve missing health; weapon changes SHALL not
heal. Replacements SHALL use the latest tiers without changing their deadline.

#### Scenario: Upgrade an injured warrior
- **WHEN** an owner upgrades armor while its warrior has 30 missing health
- **THEN** the same warrior receives its new maximum health with 30 missing health
- **AND** a weapon upgrade changes damage without restoring health

#### Scenario: Purchase during replacement
- **WHEN** an owner upgrades equipment while awaiting a replacement
- **THEN** the original 15-second deadline remains unchanged
- **AND** the replacement uses the new equipment tiers

### Requirement: Protected arena combat

The server SHALL target living enemy warriors and claimed enemy player
characters only. Both combatants SHALL be inside the current battlefield bounds
before damage. Owners, friendly actors, unclaimed players, and actors outside
the arena SHALL remain immune. Attacks SHALL require melee reach, line of sight,
and a server-enforced cooldown. Leaving the arena SHALL end pursuit.

#### Scenario: Enemy enters melee reach
- **WHEN** a living hostile actor is inside the arena within melee reach and sight
- **THEN** the warrior deals its inherited damage at most once per cooldown

#### Scenario: Enemy retreats to its settlement
- **WHEN** the target exits the arena
- **THEN** pursuit ends and no further damage is dealt outside the arena

### Requirement: Authoritative bounded army lifecycle

The server SHALL own NPC physics and combat decisions. Leaving or releasing an
owner SHALL cancel navigation, attacks, and replacements. Dead corpses SHALL
be removed after a bounded delay. Client data SHALL not determine damage or
ownership.

#### Scenario: Owner leaves during navigation
- **WHEN** the owner leaves while its warrior is moving or attacking
- **THEN** the unit and its pending work are removed without delayed damage
