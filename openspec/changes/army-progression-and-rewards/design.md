# Design

## Context

Existing claims, economy, gear and one-slot armies are authoritative on the
server. Player weapons are visual only. See proposal.md for the requested
progression and confirmed choices. User canceled eight-client testing previously;
verify this change with focused Studio suites and a small multiplayer run.

## Goals / Non-Goals

Use one damage/reward authority for player, melee NPC, and ranged NPC attacks.
Keep the existing army lifecycle and session-only economy. No persistent data
migration, Marketplace imports, formations, ranged player controls, or third slot.

## Decisions

- UpgradeTracks owns gear balance and barracks costs, settlement requirements,
  respawn delays, and capacity. Economy snapshots gain barracksLevel=1. Values
  stay per owner; unopened accounts cannot receive rewards or upgrades.
- Economy.rewardKill awards a fixed 10 without spending click-rate tokens.
  CombatService validates registrations/current claims and both arena bounds,
  range, sight, and cooldown before damage. It detects an actual living-to-dead
  transition synchronously and consumes a weak-key Humanoid reward guard before
  publishing. No last-attacker death tag: environmental deaths earn nothing.
- CombatService.new(world,registry,economy,publish) exposes register, unregister,
  actor, actors, hit, and destroy. Registrations capture owner/civilization and
  role; player models must be the owner's current Character. Damage comes from
  current economy tiers, with ranged damage floor(tierDamage*0.8). Hits require
  five-stud melee reach or 45-stud ranged reach; cooldowns are one/two seconds.
- PlayerCombatService accepts only an attack intent. It checks a living current
  character and genuine equipped generated gear, throttles missed swings, then
  chooses the nearest visible enemy in a forward cone. A client Tool.Activated
  bridge sends no damage/target payload. This is melee even for musket/bow skins.
- PadCatalog defines actual tier pads. Retain coin and settlement controls;
  create additional unlocked tier pads, remove purchased ones, and bind their
  fixed expected preceding tier. All next-tier purchases require that same
  settlement level: tier 2/3/4 at settlement 2/3/4. Stage one has only coin and
  settlement pads. Economy independently enforces the level cap.
  Dynamic binding teardown and contact latches prevent stale/standing purchases.
- Floor layout uses existing forecourt plus expansion edges: gear tier two
  at x±12,z24; tier three x±12,z31; tier four x±24,z24. Barracks tiers two,
  three, four at x0,z24/31/38. Pads are 8×1×6, coin/settlement x±12,z14.
  Geometry tests cover all civilizations, stages, and transformed plots.
- WarriorService owners hold independent warrior/ranged slots. Existing get.rig
  and get.respawnAt alias the warrior for compatibility; snapshots also expose
  slots. At death, snapshot the current barracks delay exactly once. A later
  upgrade changes future deaths only; tier four adds ranged without rebuilding.
- NPC registration/unregistration links army identity to CombatService. Up to
  sixteen NPCs and eight players remain targetable (24 actors). Navigation remains
  bounded, asynchronous, generation-checked, server-owned, and teleport-free.
- TroopProjectile advances noncolliding visual shots with server segment
  raycasts. No homing or Touched damage. Cap active shots, distance and lifetime;
  cancel on shooter death or departure. Service revalidates both actors before
  delegating impacts to CombatService. Obstacles/protected bodies stop shots.
- RangedConfig maps all 13 civilizations: Spartan/Roman javelins, British and
  Ottoman muskets, Seneca/Mongol/Persian/Japanese/Mauryan bows, Viking throwing
  axes, Spanish/Ming crossbows, and Egyptian slings. WarriorRig/Equipment accept
  the class and reuse armor/health logic once. Both troops inherit gear.
- HUD shows actual barracks tier, capacity, per-slot status and countdowns,
  settlement-gated prices, and kill-reward feedback. Building signs reflect tier.

- Store the five user-provided model exports as repo-owned binary RBXM assets,
  mapped by Rojo to ServerStorage.NPCTemplates. NPCModelTemplates clones and
  sanitizes before parenting: remove embedded logic/tools/forces/external links,
  validate R6 body joints, normalize existing connections to one motor per pair,
  attach loose cosmetics, and unanchor every part. Preserve source clothes and
  headwear; tier gear overlays them. Only melee uses these templates; unsupported
  or absent rigs use existing procedural generation with a warning for invalid
  configured templates. Never mutate originals or stored templates.

- Claimed plot identity moves into civilization-styled main-hall facade details;
  use surface text and small architectural trim within the building silhouette.
  Preserve a plot marker for unclaimed plots. Rebuilds update owner/civilization.

## Risks / Trade-offs

- Moving projectiles can miss moving targets; this is intentional. Recheck sight
  and arena bounds at impact for conservative protection.
- Rebuilding pad bindings can leave listeners or stale references; retire only
  owned tier pads and disconnect bindings while preserving active contact latches.
- Army and currency changes can invalidate old exact-balance tests; keep native
  click assertions in combat-free runs and test rewards separately.
- Shared gear changes affect every actor; retain deficit/downgrade regressions.
- Studio startup is environment-sensitive; small runtime checks are required,
  while published-client, device hardware, and eight-player tests remain future work.

## Migration Plan

No saved profiles exist. Fresh Play sessions start barracksLevel at one. Update
the runtime modules through Rojo and restart Play. Reverting this change restores
the prior session schema; no stored currency or upgrades are migrated.

## Sources

- https://create.roblox.com/docs/reference/engine/classes/Tool
- https://create.roblox.com/docs/reference/engine/classes/Humanoid
- https://create.roblox.com/docs/workspace/raycasting
- https://create.roblox.com/docs/scripting/security/client-server-boundary

- https://create.roblox.com/docs/reference/engine/classes/SerializationService
