## Purpose

Give unlocked Spartan player and melee shields visible, limited frontal protection using the game's existing validated combat authority.

## ADDED Requirements

### Requirement: Shared player and melee shield protection
Eligible Spartan players and melee troops SHALL use the same inert shield asset after Shield Training I. Two accepted hostile hits within the forward 120-degree arc SHALL each consume one charge and prevent that hit's damage. Side/rear hits SHALL bypass the shield. Ranged troops, medics and other civilizations SHALL NOT receive this protection.

#### Scenario: Break a shield
- **WHEN** two distinct validated frontal attacks contact an eligible shielded life
- **THEN** the first leaves one charge and the second removes the shield visibly, with no damage or kill reward from either blocked hit

### Requirement: Shield authority and lifetime
Rejected, protected, obstructed, duplicate or cooldown-blocked contacts SHALL NOT consume shield charges. Ordinary and skill damage SHALL share shield protection. New lives SHALL receive fresh shields; equipment rebuilds, healing, purchases and formation commands SHALL preserve spent charges. Source assets SHALL remain immutable.

#### Scenario: Rebuild damaged equipment
- **WHEN** armor changes or appearance reloads after a shield has broken
- **THEN** the life remains unshielded until respawn and unrelated avatar items remain intact

#### Scenario: Invalid contact
- **WHEN** a friendly, stale or otherwise rejected attack reaches a shielded actor
- **THEN** its shield charges and health remain unchanged
