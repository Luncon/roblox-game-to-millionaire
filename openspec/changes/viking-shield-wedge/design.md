# Design

## Context

See proposal.md. FormationConfig definitions already drive purchase eligibility, profile validation, War Council UI, map markers, shields and rack creation. ArmyFormation owns captured-life geometry; WarriorService validates combat actors and releases formation control without respawning troops.

## Goals / Non-Goals

Goals: introduce one distinct offensive formation through the existing coordinator and verify both its geometry and contact transitions. Non-goals: a new target-selection system, charge damage, new shield art, formation axe skills while held, or changes to other factions' release behavior.

## Decisions

- Add `viking-shield-wedge`, with center front at (0,0,-6), flanks at (+/-5,0,0), and supports at (+/-3,0,8). A six-stud lead visibly separates it from Sparta's two-stud arc. All guards face forward. Use a contact-release flag rather than hard-coding a civilization in the coordinator.
- Evaluate contact against the three captured frontline lives, verifying both rig and Humanoid identities. WarriorService supplies ordinary CombatRules.canDamage at the existing five-stud melee range, canAct and visibility checks against current authoritative actors. No client contact signal or extra damage path is introduced.
- Evaluate release before positional cohesion so an attacking/avoiding/lagging member cannot deadlock it. Explicit holding suppresses contact release. Existing casualty, destination and order paths remain canonical; release clears stale motion, restores normal speed and leaves living identities, shield charges, skill deadlines and respawn deadlines intact.
- Shared persistent fields already accept definition IDs by civilization. New Viking selection uses existing version-one keys and optional recruitment validation; no new stored values beyond the selected identifier. Shield refresh and rack collection inherit eligibility from the definition.

## Risks / Trade-offs

- Wider lead could make bridge travel or road assembly stall → use the existing formation navigators/cohesion limits and verify actual unanchored road travel.
- Proximity might include allies, stale lives or blocked enemies → adversarial deterministic tests and native occlusion/arena checks.
- Contact release may happen before an attack actually lands → intentional: validated ordinary melee reach triggers free combat immediately, avoiding a stationary formation waiting through attack windup.
- Global definition affects geometry fixtures → run all native module cases plus existing formation runtime regressions.

## Migration Plan

No data migration or dependencies. Verify with standalone Luau, strict OpenSpec validation and an isolated fake-store Studio playtest. Install production sources into the existing main Studio after verification; publishing and real multi-owner/storage tests remain separate. Rollback removes the definition and contact policy together; saves that selected this new identifier need clearing before reverting to old code.
