# Design

## Context

See proposal.md. Existing formation presence implies shield eligibility, a shared 3/1/1 role map, fixed front-line geometry and one archer. Recruitment already supports 1/3/1 with stable IDs: warrior is melee; camp, reinforcement and ranged become archers. CombatEncounter owns validated, exactly-once windup/contact/recovery and already provides bounded screen guards and ranged escapes.

## Goals / Non-Goals

Goals: express the new composition and shieldless policy explicitly, reuse ordinary attacks and navigation, and isolate coordination to captured Seneca lives. Non-goals: a second combat engine, new weapon stats, new networking, new save fields or Japan's formation.

## Decisions

- Add optional per-definition roles and a shield-support predicate. Legacy definitions retain their existing role map and shield requirement. Use the predicate for purchases, save validation, shield refresh and racks so adding a non-shield formation never accidentally equips shields.
- Keep existing persistence schema and optional Barracks counts. Resolve formation requirements using civilization or the selected definition. Faction-aware validation rejects Seneca/Japan shield levels, and shieldless formation state is accepted only for the appropriate definition.
- Give Seneca a 20-stud-wide shallow crescent: left/right archers at x +/-10,z2; center archer at z5; guard z-6; medic z11. Geometry rotates with the road. A separate formation shape branch avoids enforcing the old three-frontman shape on archers. The guard remains the casualty-release life.
- Add a small SenecaVolley policy module for captured-archer identity checks, stable shared target selection, retained target life and a shared next-windup deadline. WarriorService supplies ordinary canDamage/canAct/visibility checks. No client target or clock is trusted.
- CombatEncounter accepts an optional focus target and attack gate/start callbacks. Locked ordinary actions keep their target and contact; only new legal attacks reserve the shared 0.45-second gate. Normal per-unit cooldowns remain authoritative. A blocked archer falls back to ordinary target choice and safe sidesteps.
- Deployed Seneca members use existing screen guard bounds: guard 14, archers 8. Ranged guards fire from any normal in-range location rather than chasing toward the ordinary preferred 35-stud distance. Existing free/terrain/arena/separation checks constrain movement. Hold freezes movement but retains focus/stagger/healing; explicit orders use canonical cancellation.
- Keep the selected screen deployed after target loss. Remove lost captured archer/medic lives without adopting replacements; guard loss or zero captured archers releases through the existing Advance/Hold transition.

## Risks / Trade-offs

- A broader role model touches shared behavior → deterministic compatibility checks plus native existing-formation regressions.
- Concentrated fire might overwhelm opponents → no damage/range/fire-rate increase; blocked sight, guard loss and local movement bounds provide counters.
- Wide crescent may meet narrow crossings → native unanchored full road march before acceptance, retaining existing formation navigation.
- Repositioning may interrupt shots → reuse existing action planting and contact cancellation, never fire while an attack is invalid or moving.

## Migration Plan

No data migration or dependencies. Implement and verify policy/progression first, then ordinary combat coordination, then native fake-store composition/purchase/selection/march/combat/command scenarios. Preserve the user's playtest and use one owned verification window. Install production sources in main Studio after verification. Published multiplayer, physical mobile/controller input and real storage restoration remain separate checks. Reverting after Seneca selections have saved requires clearing the new selected identifier first.
