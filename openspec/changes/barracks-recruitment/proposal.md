# Proposal

## Why

Troop capacity is split between the Barracks and Army Camp, making recruitment hard to understand. Players need one recruitment screen that controls their army composition.

## What Changes

- Consolidate combat capacity purchases at the Barracks, retaining settlement 2/4/10/18 milestones, prices, prerequisites and existing purchased capacity.
- Remove the separate Army Camp building and use the Training Yard as the gathering area. Move the Barracks beside the yard, opposite the War Council, as approved by the user.
- Add an owner-only Barracks recruitment screen with melee/ranged counts and an independently hospital-limited medic count. Composition changes affect future spawns, preserving living troops and pending deadlines.
- Newly spawned shield-eligible melee physically collect shields before joining their orders. Existing spent-shield Regroup resupply remains available.
- Correct the Persian spear orientation for its holders and animations. Close the Persian screen to 30 studs and slow its final approach to half speed after entering clear bow range.
- Design choices: permit zero selected troops; preserve legacy automatic lineup until a composition is explicitly saved; keep the version-one storage keys for purchased capacity as compatibility fields.
- Outside scope: increasing the five-troop maximum, additional classes, new formations, stat balance changes and matchmaking.

## Capabilities

### New Capabilities

- `army-recruitment`: Barracks capacity, saved composition, recruitment interaction, troop life continuity and equipment collection.

### Modified Capabilities

None; gameplay specifications currently live in earlier change directories.

## Impact

Shared recruitment/progression configuration, profile validation, Economy, troop service, world geometry and navigation reservations, physical controls, server remotes, recruitment and army HUD, fixtures and player documentation. No new dependencies or real-data fixtures.
