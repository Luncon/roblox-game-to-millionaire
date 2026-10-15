# Proposal

## Why

The current flat arena and tightly packed four-stage settlements cannot support
the player's intended journey from a small civilization to a magnificent capital.
The next milestone needs room to grow, a varied battlefield and gradual upgrades
whose combat advantage stays bounded.

## What Changes

- Expand the eight-plot circular world and shared battlefield, with reserved room
  for fully grown settlements and distinct grassland, forest, desert, snowy
  highland and wetland scenery, waterways and dry crossings.
- Extend settlement, weapon and armor progression to 50 levels. Each settlement
  increment adds a small amount of land and lasting themed visual detail; level
  50 completes the civilization's settlement. Keep the cap configurable.
- **BREAKING balance change:** replace four large gear jumps with 50 small linear
  steps, proposed damage 10–18 and health 100–140. Preserve every stored coin and
  numeric level; old level four becomes level four on the new curve.
- Retain protected settlements, one-coin ground earning, ten-coin final hits,
  exclusive civilization ownership and independent saved profiles.
- Keep upgrades bounded by settlement level, with physical floor controls that
  remain usable throughout growth. Barracks retains its four levels and two-slot
  maximum; its extended progression is outside this change.

Confirmed requirements are level-50 gradual settlement growth, gradual balanced
weapon/armor upgrades, greater plot separation, and diverse biomes. Exact map
dimensions, stat endpoints, prices, biome placement and architectural milestones
are implementation choices to validate in Studio. Matchmaking, army commands,
formations, new troop classes and battlefield reward objectives remain separate.

## Capabilities

### New Capabilities

- `world-landscape`: spacious protected plots, biome scenery, traversable shared
  battlefield and equivalent routes for automatic armies.
- `settlement-growth`: deterministic themed growth through 50 levels, reachable
  floor controls, final footprints and restored saved settlements.
- `equipment-progression`: small bounded weapon/armor improvements across 50
  settlement-gated levels with player and NPC inheritance.

### Modified Capabilities

None in the main spec inventory. This supersedes the four-level settlement/gear
behavior recorded in earlier in-flight changes; their completed test records
remain historical evidence.

## Impact

Shared progression/configuration and pad catalog, profile validation, settlement
and landscape builders, physical pad/controller behavior, gear cosmetics and
fractional combat damage, HUD, Studio fixtures and documentation. Existing
DataStore name, scope, schema and per-civilization keys remain unchanged. No new
dependencies or Marketplace scripts are needed.
