# Proposal

## Why

Wounded armies currently fight until death or wait for replacements. A hospital should add a dedicated backline medic and let troops recover at their training yard, giving players a reason to protect support units and regroup.

## What Changes

### Confirmed requirements

- Add a purchasable hospital behind each settlement. Building it unlocks both a medic class and training-yard troop healing.
- The hospital deploys one independent medic slot, separate from barracks and Army Camp reinforcements. A fully developed army can contain four troops: melee, ranged, camp reinforcement and medic.
- Medics throw visible bandages to damaged owned troops from a distance, prioritize helping wounded troops and actively avoid enemies while advancing. Movement heads directly to the battlefield, then uses the living troop average without rearward support travel.
- Medics obey army orders. Hold stops movement while fighters continue their existing in-range attacks and the medic continues in-range healing. Regroup returns the whole army to its owner's training yard.
- Hospital-enabled troops recover while physically inside their own training yard. Health never exceeds maximum and dead troops cannot be revived.
- During Advance only current enemy avoidance permits backward medic movement; Regroup remains its explicit return command. Critical fighters retain attacks within medic range using 20%/40% thresholds. Bandages heal one nearest eligible troop within a small three-stud radius, including near misses against moving troops.

### Proposed defaults for this first slice

- Hospital I: settlement 10, purchased Training Yard I, 200 coins; Army Camp ownership is not required. No hospital upgrade tiers yet.
- Hospital medic respawn: a separate fixed 15-second wait, unaffected by barracks upgrades. Spawn at the hospital, then join the current army order.
- Bandages: 12 health per successful contact, a three-second launch cooldown and 45-stud maximum range. One pending bandage per medic; no attacks, weapon skills, self-bandaging or player healing.
- Advance travels directly to the battlefield and supports the average of living owned fighters there. Injured patients are selected independently for bandages while moving. Patient chasing, escort selection, timed retreats and barracks/reinforcement fallback are removed. Actual enemy avoidance permits backward steps. Hold does not chase heal targets or flee; it preserves the existing stationary command contract.
- Training-yard recovery: five health per second after two continuous seconds inside the owned yard. Leaving, recent damage or lost profile authority resets eligibility; Regroup is the convenient return command, not a prerequisite for healing once inside. Recovery also works while the medic is dead or respawning.
- Use existing civilization outfits with an original bandage satchel and throw animation; no imported character/equipment dependencies. Initial numbers are prototype tuning, not measured balance claims.

### Outside this change

Player healing, revival, allies across owners, offensive medics, hospital upgrades, paid consumables, healing-based currency rewards, saved troop health, offline recovery, new combat formations and mounts remain outside scope. Existing weapon-skill fixes and their verification boundaries are preserved.

## Capabilities

### New Capabilities

- `hospital-progression`: Hospital purchase, rear placement, persisted ownership and its separate deployment capacity.
- `medic-support`: Independent medic lifecycle, battlefield support movement, bandage healing and army-command integration.
- `troop-recovery`: Hospital-gated healing inside an owned training yard, with live authority and lifecycle guards.

### Modified Capabilities

None under the current main-spec inventory, which contains only `development-workflow`. Existing army, settlement, profiles, training and weapon contracts remain in their change artifacts; this change extends those implementations while preserving their existing guarantees.

## Impact

Extend SettlementDevelopment/SettlementSites, ProfileData/Economy and every snapshot/publication/copy path with a missing-only `hospitalLevel` default, preserving version-one profile keys/scopes and the original fifteen fields. Add hospital construction/terrain reservations and a next-eligible pad; reuse the current owned-slot lifecycle, navigation, army commands, gear/outfit conventions and fake-store harness.

CombatService must register medics as damageable owned actors while explicitly excluding them from ordinary attacks and weapon skills. Healing needs its own server-only validated path; neither client health/targets nor the hostile-only damage API can authorize it. HUD counts/status gain a medic slot and Hospital readiness without changing the camp class enum.

All support state, targets, projectiles, live health and recovery clocks are transient. Runtime acceptance requires one isolated solo Studio session, native visual/path/health checks and a focused two-owner isolation check; specification validation and Rojo builds are separate evidence. No gameplay is implemented by this proposal.

Critical support retains normal attacks within healing range using 20%/40% thresholds. Medic movement uses direct battlefield deployment and troop-average support; only current enemy avoidance and Regroup can move it backward.
