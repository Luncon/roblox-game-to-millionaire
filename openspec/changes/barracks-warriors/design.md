# Barracks and first warriors

## Context

The existing server owns claims, economy, themed settlements, and equipment.
Army state must survive rebuilding a settlement and resetting a player character.
The user confirmed one automatic melee troop and a 15-second death replacement,
then requested inheritance of weapon and armor upgrades.

## Goals and boundaries

Deliver a free level-one barracks at settlement stage 2, one live warrior per
owner, authentic movement to the arena, and server-authoritative melee combat.
Saving, ranged classes, formations, combat rewards, higher barracks tiers, and
player-controlled weapon attacks remain future work.

## Decisions

- Put tuning and all 13 melee variants in shared WarriorConfig. Use weapon
  damage 10/15/22/30 and armor health 100/120/150/200 from existing UpgradeTracks.
- Equipment gains an explicit model API. WarriorRig creates an unanchored R6
  humanoid with Motor6Ds and owns procedural walk/swing poses. One equipment
  helper owns health updates, preserving the missing-health deficit exactly
  once; do not stack two armor bonuses.
- Keep troops in world.model.Troops, separate from rebuilt Settlement folders.
  The barracks replaces the west camp at stage 2. Spawn transforms derive from
  the current Foundation CFrame, including moved and rotated plots.
- WarriorService.start(world, registry, economy, catalog) exposes refresh,
  release, get, and destroy. Records hold identity generations, the live rig,
  and replacement deadline. Death records the deadline once. Gear refresh
  updates a live model in place or leaves a pending deadline intact.
- Use Workspace:GetServerTimeNow for replicated countdown deadlines. Publish
  BarracksLevel, WarriorCount, WarriorRespawnAt attributes. Character resets
  never reset army state. Initial eligibility deploys immediately.
- SetNetworkOwner(nil) after parenting unanchored rigs. A bounded 0.2-second
  server loop scans at most eight troops and eight players. No damage remote.
- Navigator uses asynchronous PathfindingService routes with one in-flight
  computation per unit, bounded replanning, blocked handling, and generation
  checks after yields. Target loss cancels old paths immediately. No teleport
  fallback. Citadel rear walls require routing through or around the gate.
- CombatRules tests current cylinder-local bounds (local Y/Z radii and a
  16-stud local X vertical tolerance), finite inputs, distinct claimed owners,
  living state, and five-stud range. Service rechecks current registry/model
  identity, arena membership, line of sight, cooldown, and damage immediately
  before TakeDamage. Aggro radius is 35 and movement speed is 12.
- Corpses last three seconds; replacement waits fifteen seconds from death.
  Release/destroy invalidates callbacks, removes corpses, and cancels work.

## Risks and validation

Pathfinding around all settlement stages, live humanoid physics, line of sight,
and actual 15-second timing require Studio checks. Pure boundary tests alone
cannot prove these behaviors. Test all 13 civ rigs and tiers, transformed map
spawns, settlement pad clearance, live gear inheritance, dead-state purchases,
cleanup, ownership immunity, actual NPC combat, and two-client player targeting.
Preserve the existing economy, map, equipment, and physical-input suites.
The user additionally requested a full eight-player test. Use eight actual Studio
clients with distinct civilization claims, native ground input, and production
warriors. Staged client startup may reduce launch contention; distinguish engine
startup failures from gameplay assertion failures and record both honestly.

## Sources

- https://create.roblox.com/docs/characters/pathfinding
- https://create.roblox.com/docs/physics/network-ownership
- https://create.roblox.com/docs/scripting/security/network-ownership
- https://create.roblox.com/docs/workspace/raycasting
