# Proposal

## Why

Rojo is connected and both startup scripts run in Studio, but the game has no
playable behavior. The next step is a small multiplayer selection-and-claim loop
that makes the planned battlefield layout tangible.

## What Changes

- Generate a placeholder central battlefield, eight surrounding plots, and an entry spawn.
- Offer Sparta and Britain with live availability, pending, rejection, and claimed states.
- Let the server assign one available plot per player and allow only one owner per civilization.
- Move claimed players to their plots, retain claims on respawn, and release claims on departure.
- Add focused claim-rule tests and a Studio multiplayer playtest guide.

The circular layout and exclusive civilizations are confirmed requirements.
Two prototype civilizations, automatic plot assignment, placeholder structures,
and no switching until leaving are implementation choices for this slice.

Saved progress, upgrades, combat, troop formations, full civilization artwork,
and cross-server matchmaking are outside this change. The selection screen
must identify this as a session-only prototype; it must not imply progress is saved.

## Capabilities

### New Capabilities

- `battlefield-layout`: Generated prototype battlefield and eight identifiable settlement plots.
- `civilization-claims`: Server-owned civilization selection, exclusive plot assignment, lifecycle, and client feedback.

### Modified Capabilities

None.

## Impact

Changes the server and client bootstrap scripts and adds focused Luau modules,
shared civilization data, tests, and playtest documentation. It adds no external
runtime services, data-store writes, paid assets, or Node runtime dependencies.
The map is generated inside one owned Workspace model when a playtest starts;
the existing Studio-built Workspace remains outside Rojo's mapping.
