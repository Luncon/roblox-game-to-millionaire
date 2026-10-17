# Design

## Context

See proposal.md. Owned and neutral services independently pick nearest actors every 0.2 seconds and navigate to enemy roots. Their shared collision group disables mutual collision; precise footwork is absent. Navigator arrival/replan tolerances are 2/6 studs and 1.5 seconds. CombatService validates immediate hits; TroopProjectile validates nonhoming shots and final hits. WarriorRig applies a generic 0.35-second arm motion after damage. The normal maximum is 24 owned NPCs plus three neutrals. Five imported R6 melee rigs have custom RestC0 orientations.

## Goals / Non-Goals

**Goals:** Coordinate one encounter model across both NPC services, make close movement and strike timing reliable, preserve combat authority and render convincing weapon motion on existing art.

**Non-Goals:** New stats, hard NPC collision, teleporting separation, new client attack authority, profile fields, capture objectives or formation bonuses.

## Decisions

- CivilizationService creates one CombatEncounter coordinator and injects it into both NPC services; isolated service tests may own a fallback coordinator. Shared reservations prevent the two services independently assigning overlapping approaches. CombatTactics provides pure scoring/geometry/timeline helpers; TacticalCombatConfig freezes tuning.
- Encounter.step performs target selection and movement planning at the existing think rate. Encounter.advance runs each Heartbeat for phase transitions and exactly one contact attempt without rescanning actors. The action locks its original target. cancel releases reservations/actions while retaining cooldown; forget removes lifetime state; destroy removes all state. A read-only get snapshot supports independent tests.
- Stable targeting uses deterministic tie breaks and hysteresis. Melee considers threats near friendly ranged troops and crowding. Attack positions form a bounded ring around a target; choose an open nearby side, retain an approach where possible and wait/retarget on overflow. Add local separation including deterministic coincident fallback. Mutual hard collision was rejected because it creates pushing/pileups and affects player movement.
- Existing pathfinding remains for long travel. Near engagements use guarded Humanoid movement with tighter arrival tolerance, terrain-grounded destinations, obstacle/body clearance and arena containment. Use Topography through the map Ground frame and native ground/obstacle checks. Do not move roots by teleport to separate bodies.
- Ranged maintain a useful distance band, retreat at a lower speed for a bounded displacement/time and sidestep blocked firing lines. Hysteresis limits back-and-forth jitter; attacks stop movement and face the locked target. Hold remains fixed; Regroup cancels contacts/projectiles and uses the existing camp behavior.
- Damage still flows only through CombatService.hit, and projectiles still use TroopProjectile.fire/step. At contact re-read both actors and validate profile-write authority, hostility, arena, range and line of sight. An attack consumes its cadence even if missed/cancelled, preventing order spam from bypassing waits. Existing 1-second melee and 2-second ranged cooldown floors remain. A successful contact updates accepted-hit evidence for visual reactions.
- Use torso-space procedural R6 weapon-family poses while preserving RestC0. Replicate C0 as the current system does. Implement spear/javelin thrust, sword slash, axe chop, bow draw/release and firearm/crossbow aim/reload. Hit feedback is brief cosmetic recoil/flash and a vetted inert sound if available. Marketplace permission was granted, but no compatible permission-verified animation library was found; importing unrelated gameplay scripts is unnecessary.
- No saves or economy schema changes. Transient target/reservation/phase state is removed on death, despawn, order changes, claim switches and teardown. Selection/lease/reward authority remains on the server.

- Shared CrowdMovement registers each owned/neutral navigator in its generated world. Short prospective legs include all live neighboring troops, regardless of hostility or orders, with height separation, velocity prediction and stable passing direction. Nearby shared destinations yield by distance/stable identity. Detour-only movement predicates preserve medic forward/enemy clearance and in-range fighter support without constraining ordinary path waypoints. Grounded deviations keep water/obstacle checks; camp detours stay inside the yard and outside the fire. Yielding resets the progress watchdog without jumping. Held troops remain obstacles and never move themselves. Direct camp legs refresh at think frequency and use four staggered reachable entry points inside the reserved wall gate.
- TroopFootwork retains finite goals with deterministic per-life variation in distances, pauses and directions. Idle shuffles stay within 3.5 studs of the assigned rally. After contact, melee take small 3.5–4.5 stud radius arc/pressure/yield adjustments; ranged take 2–3.2 stud lateral steps. Stop optional steps before recovery ends. Windup/contact, skills, Hold and Regroup override footwork; ordinary contacts/cooldowns stay unchanged. Shared reservations and medical support bounds validate every combat step. R6 hip poses follow lateral velocity; idle weight shifts never move the root.

## Risks / Trade-offs

- Noncolliding bodies or a moving player can still briefly intersect → prove reduced sustained torso overlap with unanchored runtime sampling; do not claim all weapon/mesh intersections disappear.
- Both sides adjusting around moving targets can circle or oscillate → stable approach reservations, deterministic choices, tighter local movement and bounded ranged retreat.
- Frame-level updates could scale poorly → target planning stays at think frequency, no path rebuild per frame, and normal-maximum crowd cases exercise geometry/state cleanup.
- Generic poses could look wrong on imported gear → preserve rotated rest joints and inspect close-up rendered spear/blade/bow/firearm exchanges on actual clients.
- Existing anchored duels cannot detect movement failures → add a six-NPC native fake-store demonstration plus focused interrupt/crowding checks; use two real clients for cross-client rendering evidence where Studio supports it and report any unavailable runtime check explicitly.

## Migration Plan

Sync repository-managed scripts through Rojo, run focused module checks then an isolated one-client fake-store encounter. Review the diff independently, verify rendered fights and a focused two-client replication/authority check without simultaneous playtests. Restore normal startup and remove owned fixtures. No published teleport or real data-store test is needed. Rollback restores the previous services/navigation/poses and removes the new encounter modules; preserve unrelated uncommitted farmer, camp and neutral work.
