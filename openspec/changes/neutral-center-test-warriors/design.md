# Design

## Context

See proposal.md for motivation. CivilizationService creates one shared CombatService used by player melee and WarriorService. CombatService currently requires a live Player, registry claim and economy state for every actor. CombatRules and TroopProjectile compare owner IDs directly; neutral enemies cannot safely be represented by a fabricated player ID, especially because Studio players use negative IDs.

WarriorRig.create requires a civilization variant and may clone a custom melee template. Topography.sampleHeight follows the landscape collision triangles. Existing tests execute inside Studio and inject fake profile stores.

## Goals / Non-Goals

Goals: support three explicit server-owned actors through shared combat, retain existing player validation and make neutral service cleanup independent of player departure.

Non-goals: general NPC faction infrastructure, fake player claims or profiles, new client authority, persistence changes or rewriting the owned-army service.

## Decisions

1. Add an explicit neutral registration path to CombatService. A private server record identifies neutral membership, validates the rig's dedicated world folder and supplies fixed basic stats. Client attributes alone never authorize registration. Neutral records have no player or economy lookup. Keep the existing owned-actor registration and validation checks. Alternatives: fabricated player IDs risk Studio collisions; bypassing combat would lose protection and projectile validation.

2. Centralize hostility in CombatRules and use it in WarriorService targeting, projectile fire/impact and damage checks. Two neutral actors are friendly; a registered neutral and a valid claimed owned actor are hostile; two owned actors retain their owner-ID rules. The neutral identity must originate in CombatService, never an arbitrary rig attribute. Alive, arena, range and visibility checks still apply. In CombatService.hit, use fixed stats for neutral attackers and award rewards only to a validated owned attacker through the existing rewardKill path. Neutrals never receive a reward or invoke a profile lookup. This is smaller than a general faction system.

3. Add NeutralOpponentConfig with enabled=true for the current prototype, respawnDelay=10 and three stable spawn slots, plus NeutralOpponentService. Ground separated center offsets with Topography.sampleHeight. Each slot owns one live rig, death/destruction connections, corpse cleanup, navigation, cooldown and replacement deadline. Callback identity guards prevent duplicate replacement. Use the current three-second corpse lifetime without adding it to the ten-second death-to-replacement delay. World teardown or service destruction disconnects everything and invalidates delayed work. Do not add these slots to owner HUD counts or army commands.

4. Reuse WarriorRig's procedural body and animation construction through a small generic-rig entry point, bypassing civilization template/outfit lookup. Give neutral fighters simple swords or a bow, neutral colors, readable labels and basic combat stats. Never fabricate a civilization variant or clone a custom civilization template. Reuse WarriorNavigator and TroopProjectile; keep NPC physics server-owned. Select eligible targets only within the arena using current class aggro distances; return to the center slot when idle.

5. Start the neutral service after shared combat creation in CivilizationService and expose its controller for isolated fixtures. Add explicit shutdown and world-removal cleanup. The single server configuration switch makes the test opposition removable without changing combat. No profile fields or keys change; only normal validated kill credits affect saved player coins.

## Risks / Trade-offs

- An overly broad neutral exception could bypass player protections → accept only private server registrations and test unclaimed, outside-arena, same-owner and neutral-to-neutral cases.
- Duplicate death/destruction callbacks could exceed three living enemies → stable slots, generation checks and staggered-death lifecycle tests.
- Existing raycasts may hit friendly neutral enemies → retain current protected-actor obstruction behavior.
- Test opponents provide repeatable normal coin rewards → this is deliberate prototype tuning, controlled by one enable switch.
- Spawn positions could intersect uneven terrain → sample collision-matched topography and verify native movement in Studio.

## Migration Plan

Implement combat support and regression fixtures first, then the three-slot service and startup wiring. Run specification validation and the isolated Studio suite. In one solo Studio playtest, verify generic appearances, melee and ranged retaliation, player and owned-troop attacks, normal reward, staggered ten-second respawns and cleanup. Exercise all thirteen civilizations using fake profiles; check existing orders, player protections and army caps. Record evidence and any unavailable checks in docs/PLAYTEST.md. A published teleport test is unnecessary because this feature adds no teleports. Disable the configuration switch to roll back the visible test enemies.
