# Spec Delta

## Purpose

Serve the miniature civilization game in the existing Roblox experience with production storage and a verified rollback path to the preserved full-size place.

## ADDED Requirements

### Requirement: Miniature live startup
The release SHALL start the existing miniature world, UI, economy, civilians, military buildings, mounts, research and outpost combat on Roblox servers. The server SHALL remain authoritative for saved state, actions, currency and combat.

#### Scenario: Join the replacement
- **WHEN** a player joins a new server of the published release
- **THEN** the miniature game starts and permits civilization selection only after writable profile loading
- **AND** ordinary purchases, placement, production, selling, research and army orders remain available under their existing guards

### Requirement: Release excludes development fixtures
The published artifact MUST contain no automated client bot, diagnostic autorunner, test currency grant or startup dependency on fake storage. Ordinary local previews SHALL remain usable without touching live player records.

#### Scenario: Verify release contents
- **WHEN** the production artifact is inspected before publication
- **THEN** it contains exactly one gameplay bootstrap and client Main
- **AND** neither test profiles nor legacy gameplay bootstrap can start

### Requirement: Replace the authorized experience
Publication SHALL target Clash of Civilizations place 73839918762778 in universe 10770758443 owned by SmithLucas5652. A preserved prior place and release manifest SHALL identify the target and rollback steps. Deployment success SHALL be distinguished from local Studio and fake-store test results.

#### Scenario: Publish and verify
- **WHEN** a tested release is published to the authorized place
- **THEN** its published version and target identity are recorded
- **AND** fresh live-server startup and a real save/rejoin check are verified separately or explicitly reported as unverified
- **AND** legacy profile storage remains untouched
