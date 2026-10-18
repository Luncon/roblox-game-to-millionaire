# Design

## Context

See proposal.md. Formation definitions already drive progression, save validation, shields, council UI/map geometry and stationary skills. ArmyFormation captures five current lives; WarriorService owns physical movement. CombatEncounter shares target selection, reservations and guarded movement with neutral troops. Regroup currently delegates directly to ArmyRest, and Equipment intentionally never refills depleted shields on rebuild.

## Goals / Non-Goals

**Goals:** Add a distinct deployed archery tactic and an explicit physical replenishment route, reusing existing authority and navigation.

**Non-Goals:** New currencies, save fields, troop types, imported models, combat-stat bonuses, player resupply, shared shields or automatic replacement of partially damaged shields.

## Decisions

- Add a frozen Persian definition with a flat front at X -6/0/6 and rear pair at X -3/3, Z 9. Reuse six-stud pace, paid progression, two-hit shield art, muster and per-life captures. Allow one-stud front alignment tolerance so native bodies can assemble a straight line.
- Give this definition a 40-stud firing stop and six-stud guard radius. The coordinator latches a screening phase on a server-validated captured-archer opportunity (normal combat range/hostility/arena plus visible line) or final destination. Latching avoids target-motion oscillation. Deployed screens do not advance after a kill; explicit orders/frontline losses retain existing release rules. Other definitions still release at center.
- Add an optional guard boundary to shared encounter planning. Filter hostile acquisition to reachable defense targets; apply the circle to approach reservations, separation, recovery footwork and navigation detours. Return displaced/unengaged guards to their slots. Only deployed Persian melee receives the boundary. Rear archer movement stays slot-bound; medic avoidance/healing remains independent.
- Build ShieldRack from inert sanitized shield clones at a shared site north of camp, with three separated pickup points and a terrain reservation. Infrastructure keys include shield training so purchase immediately creates it. Use current plot ownership rather than cached owner metadata.
- During Regroup, spent living melee first navigate to their assigned rack pickup, then resume normal ArmyRest. A server-owned collection function checks order, owner/civilization, training, life, writable authority and proximity before resetting the existing remaining-charge attributes. Exactly-zero checks prevent repeat and partial refills; command changes discard pending travel.
- Extract shield-only visual refresh from Equipment so pickup restores the shield without rebuilding weapons, changing joints or resetting health. Ordinary refresh/depletion remains unchanged. New charges are transient and never saved; the existing version-one profile stays at twenty fields.

## Risks / Trade-offs

- Friendly bodies can occlude arrows -> place the archer behind a gap, require a real clear shot for early deployment, and observe physical releases/damage.
- Local combat can drift or bypass guard bounds -> constrain selection, approach/recovery/crowd plans and test repeated motion plus a retreating target.
- Rack travel can crowd camp or stale claims -> separated pickup points, supported reserved terrain, current claim checks and native recall/cancellation tests for all shield factions.
- Rebuilding all equipment could disrupt attack poses -> refresh only the missing shield visual and retain original asset/grip fixtures.

## Migration Plan

No save migration or data-store access is required. Add definitions/pure tests, bounded combat and deployed integration, then physical rack/resupply. Verify in isolated fake-store Studio alongside at most one user playtest. Run existing Spartan/Roman, combat, movement, medical, equipment and profile regressions; refresh production/manual/test builds, record limits, clean owned fixtures and integrate main. Rollback removes the new selection/route without overwriting failed loads or changing version-one keys.
