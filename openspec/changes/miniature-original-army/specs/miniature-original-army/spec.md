# Spec Delta

## Purpose

Preserves the original game's recognizable troop assets, outfits, animations and
baseline tactical behavior while adapting their movement and reach to miniatures.

## ADDED Requirements

### Requirement: Original troop identities

Miniature combat troops SHALL use the original army's model creation, outfits,
equipment and face/palette rules at quarter scale. The five custom melee skins
SHALL retain their original clothing and headwear. Sources SHALL remain immutable.

#### Scenario: Every civilization supplies an army

- **WHEN** a melee, ranged or medic troop is created for any of thirteen civilizations
- **THEN** its model, garments, weapon family, grips and proportions match the scaled original role
- **AND** neutral defenders use the original neutral warrior/archer models
- **AND** no source rig, template or player avatar is modified

### Requirement: Original joint animations and planted feet

Troops SHALL use original joint-driven walk and weapon-family attack animations.
Their actual feet SHALL meet the sampled ground or raised support through walking
and combat poses. Cosmetic bounds and weapons SHALL NOT determine ground height.

#### Scenario: Walking over a raised plot

- **WHEN** a troop crosses ground, a raised home plot or an outpost footing
- **THEN** its lowest posed sole follows that support without hovering or sinking
- **AND** player avatars and invisible selection boxes are excluded from support
- **AND** original body joints and equipment grips remain intact

### Requirement: Original tactical baseline

Server combat SHALL reuse the original targeting, engagement reservations,
spacing, bounded ranged retreats, phased contacts and medic planning/healing.
The miniature adapter SHALL retain fresh life, authority, sight and distance
validation while directing armies to the existing outpost objectives.

#### Scenario: A tactical encounter interrupts an attack

- **WHEN** a target changes life, range, visibility, allegiance or army authority
- **THEN** pending attacks, shots and healing cannot affect a stale or illegal life
- **AND** windup/contact remains planted with exactly-once validated contacts
- **AND** commanders, civilians and protected homes remain excluded

### Requirement: Slower movement and halved support reach

Player troop movement SHALL be capped at6studs/second and neutral movement at4.
Ranged reach SHALL be capped at10studs for player troops and9for neutrals;
medic healing SHALL require a living allied patient within7studs. Unchanged
original source configurations SHALL NOT be globally mutated to apply these limits.

#### Scenario: Targets beyond miniature reach

- **WHEN** a target or patient is beyond its applicable miniature range
- **THEN** no attack or healing is applied until legal range is reached
- **AND** planning and recovery positions permit reaching that shorter range
- **AND** movement never exceeds the applicable cap, including retreats

### Requirement: Preserve existing sandbox authority and objectives

The original-army adaptation SHALL preserve the ten-troop cap, building-owned
replacement identities, E targeting and20clear-second outpost capture with
defender pauses. Combat state SHALL remain unsaved and production services SHALL
NOT bootstrap in the isolated sandbox.

#### Scenario: An outpost is captured after the adaptation

- **WHEN** a player buys and places military structures in the fake-store sandbox
- **THEN** the original-looking army walks, fights, captures and obeys E override
- **AND** unrelated troop health/deadlines and all economy ledgers remain valid
- **AND** production, preview, backup and real player storage remain unchanged
