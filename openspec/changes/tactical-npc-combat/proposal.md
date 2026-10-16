# Proposal

## Why

NPCs currently converge on enemy roots, overlap and exchange immediate damage while playing the same brief arm motion. The user wants strategic movement and visible fighting, and has authorized implementation using a coordinator, developer, reviewer and tester workflow.

## What Changes

- Both owned and neutral troops use distinct melee approach positions, nearby separation and overflow handling around crowded targets.
- Attacks visibly wind up, strike and recover. Damage or projectile release occurs at contact after fresh server validation, with weapon-family poses, a short hit reaction and impact feedback.
- Ranged troops maintain a firing distance, use bounded retreats when threatened and sidestep obstructed firing lines. Shooting requires a stationary commitment.
- Troops retain valid targets, prefer open approaches and respond to enemies threatening friendly ranged troops.
- Preserve current stats, attack cooldowns, progression, rewards, troop capacity, protected areas, orders and respawn deadlines. Hold remains fixed; Regroup cancels pending attacks.
- Proposed implementation choices: shared encounter coordination, existing pathfinding for travel and guarded short movement near combat. Use replicated procedural R6 poses suited to custom joints; marketplace clips remain optional if verified compatible and accessible.
- Outside scope: capture objectives, formation bonuses, new classes, blocking/dodge rules, healing, morale and combat stat rebalance.

## Capabilities

### New Capabilities

- `npc-encounters`: Coordinated NPC positioning, target choice, timed attacks and combat presentation for owned and neutral troops.

### Modified Capabilities

None. The main inventory contains development-workflow only; existing army and neutral change artifacts remain the compatibility baseline.

## Impact

New shared tuning and server tactic/encounter modules; integration in owned/neutral services, navigation and R6 posing. Add focused tests and a fake-store native combat runner. Update army/playtest documentation. No profile schema, economy, network purchase API or dependency changes. Verify unanchored solo fights, rendered weapon motion and cross-client replication; no anchored duel can substitute for movement evidence.
