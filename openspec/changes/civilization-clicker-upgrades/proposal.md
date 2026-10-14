# Proposal

## Why

Players can claim settlements but have nothing to earn or improve. Expand the
agreed civilization roster and add a small playable economy before persistence,
armies, and combat.

## What Changes

- Make all 13 civilizations in GAME_VISION selectable, preserving eight plots
  and exclusive ownership. Add distinct themed placeholder buildings.
- Add a physical coin button on each plot: every accepted activation awards exactly one coin.
  Normal rapid clicking stays responsive; server bounds abusive event rates.
- Add three sequential settlement expansions with visible buildings and plot
  growth. Proposed tuning: costs 25, 75, 150; levels 1–4; plot sizes 60–84 studs.
- Add separate physical weapon and armor upgrade pads. Equip civilization-themed
  gear on claim, improve it when purchased, and restore it after respawn.
- Display server-confirmed coins, each upgrade track, affordability, and errors
  in a read-only HUD. Ground pads support click/prompt and upgrade walk-on entry.
- Keep economy session-only as explicitly chosen by the user. Saving comes next;
  no persistence, civilization switching, armies, weapon combat, abilities, or routing
  in this change.

## Capabilities

### New Capabilities

- `civilization-roster`: the full agreed roster and themed settlement presentation.
- `settlement-economy`: single-coin earning, bounded requests, and atomic upgrades.

### Modified Capabilities

None in the main spec inventory. The earlier in-flight selection prototype remains
open for physical touch/controller verification; this change supersedes its
two-choice content and fixed menu layout without weakening exclusive claims.

## Impact

Shared catalog and upgrade configuration, server economy and claim lifecycle,
generated settlement art, selector/HUD, Studio tests, and playtest documentation.
No additional dependencies or stored player-data changes.
