# Proposal

## Why

The user authorized replacing the published Clash of Civilizations experience with the miniature game. Its current development bootstrap deliberately rejects live servers and uses temporary profiles, so publishing it unchanged would not produce a playable release.

## What Changes

- Start miniature gameplay on live servers using validated, session-locked persistent profiles.
- Restore Coins, inventory, buildings, military research and army groups separately for each player and civilization. Keep combat lives, captured outposts and active-time clocks session-only.
- Retry transient profile loads, handle rapid reconnects and shutdown saves, and show actionable storage status without allowing play against an unwritable profile.
- **BREAKING** Replace the full-size gameplay in existing place 73839918762778, universe 10770758443, owned by SmithLucas5652. Preserve its old place backup and all legacy CivilizationProfilesV1 data; do not translate incompatible old progression or test funding into miniature saves.
- Keep local Studio previews and all automated fixtures on injected fake storage. Exclude test runners and test funding from the release.

Confirmed scope is the existing miniature game and publishing the replacement. A separate miniature DataStore, normal 200-Coin start and retained legacy data are implementation choices that avoid destructive conversion. New gameplay, economy rebalancing, cross-server matchmaking and universal asset redesign are outside this release.

## Capabilities

### New Capabilities

- `miniature-persistence`: Durable miniature profiles, session ownership and failure-safe lifecycle.
- `published-miniature-game`: Live miniature startup and verifiable replacement of the existing published place.

### Modified Capabilities

None.

## Impact

Miniature server bootstrap, Sessions/Runtime, storage adapter, client save-status presentation, release mapping/tooling, tests, release notes and the existing Roblox place. No dependency upgrade or legacy profile mutation.
