# Design

## Context

The current selector assumes two cards and fixed vertical offsets. The map has
eight 60-stud plots with a shared building shape. ClaimRegistry is pure and
non-yielding; CivilizationService owns the claim remotes and Player lifecycle.
Existing Studio module tests and multiplayer helpers are reusable.

## Goals / Non-Goals

**Goals:** Separate economy decisions from engine presentation, retain existing
exclusive claim behavior, and allow rapid earning without a round trip per click.

**Non-Goals:** Persistence, switching civilizations, final art, and armies. The
user explicitly chose to test the earning/upgrade loop before adding saving.

## Decisions

1. Extend the catalog with stable IDs and architecture keys. Keep all thirteen
   reference windows from GAME_VISION. A server SettlementBuilder creates themed
   primitive buildings; growth adds huts, storage, and perimeter structures.
2. A pure Economy owns zero-initialized accounts attached to claims, with three
   independent levels. It accepts no balance or reward amount. Earning permits
   a 20-click burst and refills 15 per second; purchases use per-track cooldowns.
3. SettlementProgression sets expansion prices 25/75/150 and sizes 60/68/76/84.
   UpgradeTracks adds weapons and armor with prices 15/50/125. Expected-level
   checks and non-yielding deductions protect against stale or duplicate requests.
4. TycoonButtons binds four persistent physical pads under each plot's Controls.
   The server derives player identity from ClickDetector/ProximityPrompt events,
   checks registry ownership, a living character, and range (20 studs for click,
   8 for touch). Upgrade contacts are latched until geometry confirms exit, so
   multiple limbs or standing cannot buy repeatedly. An ingress token bucket
   bounds physical-event floods before responses or rendering.
5. There is no client earning/purchase remote. EconomyRemotes.State reports to
   the owner; Coins/SettlementLevel/WeaponLevel/ArmorLevel/EconomyRevision attributes
   and leaderstats Coins replicate authoritative progress. Departure clears it.
6. Equipment attaches noncolliding themed armor and an equipped Tool for all
   thirteen civilizations. Tier metadata changes appearance and weapon Damage;
   armor grants maximum health 100/120/150/200. Application preserves existing
   health deficit and removes only generated gear. Combat hits are not implemented.
7. The entire selector scrolls with automatic canvas sizing, including notices
   and refresh, so short landscape views retain choices. A compact read-only HUD
   shows coins and three upgrade tracks while leaving the ground visible.
8. Marketplace lookup is optional. The inspected free results were generic
   statues, fantasy/IP models, or scripted NPCs, so this milestone uses procedural
   models with no external asset IDs. No scripts from external models are imported.

## Risks / Trade-offs

- Simulated clicks cannot prove human input or prevent autoclickers → bounded
  server awards, no arbitrary amounts, and no promises of bot detection.
- Event floods → bound accepted work; drop excess physical requests before
  geometry/UI work. Only successful upgrades rebuild the settlement.
- More roster choices → full scrolling layout plus last-entry/portrait/landscape tests.
- Bigger plots → cap at 84 studs, below neighboring plots' corner separation.
- Saving intentionally absent → no DataStore calls, clear notice, prepare account
  fields for later per-civilization profiles without pretending they are saved.
- Automated gamepad input was inconclusive in the previous milestone → native
  selector Activated handling and ground ClickDetector/ProximityPrompt handling;
  explicitly record remaining physical hardware input checks.

## Migration Plan

Sync with Rojo and restart Play. No saved-data migration is needed. Verify module
tests, existing claim multiplayer regression, real button earning/purchase,
respawning, and the expanded menu. The production place excludes test helpers.

## Sources

- [Client/server boundary and token buckets](https://create.roblox.com/docs/scripting/security/client-server-boundary)
- [ClickDetector](https://create.roblox.com/docs/reference/engine/classes/ClickDetector)
- [Spatial overlap queries](https://create.roblox.com/docs/reference/engine/classes/WorldRoot)
