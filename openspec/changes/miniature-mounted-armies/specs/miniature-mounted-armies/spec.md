# Spec Delta

## Purpose

Adds automatic mounted miniature troops from safe user-supplied animal models,
with unique civilisation facilities and explicit two-slot army capacity costs.

## ADDED Requirements

### Requirement: Civilisation-specific mounted facilities

Every civilisation SHALL offer a distinct named animal facility in the Military
shop for exactly 5,000 Coins without research. Its building item SHALL use the
existing inventory, plot placement and destroy-hammer reclaim flow. Each placed
facility SHALL supply one automatic mounted troop when capacity permits.

#### Scenario: Purchasing and placing an animal facility

- **WHEN** a writable living owner buys and legally places the facility
- **THEN** the server charges exactly 5,000 Coins and consumes one owned building item
- **AND** the correct civilisation's facility and decorated mounted rider appear
- **AND** stock, proximity, ownership, request replay and placement guards still apply

### Requirement: Weighted mounted capacity

Each mounted troop SHALL cost two slots under the unchanged ten-slot army cap.
Melee, ranged and medic troops SHALL retain one-slot costs. A mounted group SHALL
wait if fewer than two slots remain, and SHALL automatically backfill when room
becomes available. The HUD SHALL report weighted usage separately from mount count.

#### Scenario: Only one army slot is free

- **WHEN** an animal facility would exceed the cap by spawning its rider
- **THEN** no mounted actor is allocated and no existing group is reset
- **AND** freeing sufficient capacity allocates its one rider without another payment

### Requirement: Mounted army lifecycle and authority

Mounted riders SHALL use server-owned target selection, ordinary melee contact,
healing, death and building-owned replacement lifecycles. They SHALL obey default
outpost marching and whole-army E orders, occupy capture sites, and preserve
unrelated lives, health and pending deadlines on sync or purchase changes.

#### Scenario: A mounted army captures an outpost

- **WHEN** a normally acquired mixed army defeats defenders and occupies the site
- **THEN** mounted units contribute through the existing twenty-clear-second rules
- **AND** defenders pause capture and neutral replacements retain their deadlines
- **AND** commanders, civilians, protected homes and stale lives remain illegal targets

### Requirement: Safe supplied animal adaptation

The sandbox SHALL use the supplied animal geometry with practical miniature
proportions, civilisation riders and distinct decoration. Raw originals SHALL be
backed up separately and never mapped into gameplay. Imported controllers,
touch damage, player seats, remotes and physics movers SHALL NOT run in troops.

#### Scenario: An imported model contains its own riding script

- **WHEN** a mount template is adapted from that model
- **THEN** game clones retain its recognisable geometry with executable/control objects removed
- **AND** only the game's server combat and movement rules can affect gameplay
- **AND** original scripts and model provenance remain recorded in the import audit

### Requirement: Coherent mounted animation and presentation

Animals SHALL animate locomotion appropriate to their anatomy with riders,
equipment and decoration following one coherent smoothed hierarchy. Paws, hooves
or low reptile supports SHALL meet actual ground. Existing foot animations and
source-decal hiding SHALL remain correct through spawn, movement and replacement.

#### Scenario: A rider crosses raised settlement ground

- **WHEN** its mount moves or attacks across supported surfaces
- **THEN** animal contacts stay grounded and the seated rider and gear remain attached
- **AND** client animation cannot cause damage or change capture ownership
- **AND** removed lives leave no duplicate bodies, faces, sounds or controllers

### Requirement: Preserve sandbox isolation and existing progress

The feature SHALL remain isolated from production and real storage. Existing
validated fake profiles missing only new mount plan/stock fields SHALL load with
compatible defaults; malformed saved values SHALL fail without overwriting data.
New mount fields SHALL NOT add or enable the production mounted-power system.

#### Scenario: An existing fake profile is restored

- **WHEN** the profile predates mount plans and merchant stock
- **THEN** valid prior buildings, currency and troop groups are preserved
- **AND** mount inventory defaults only where absent and normal restocking remains authoritative
