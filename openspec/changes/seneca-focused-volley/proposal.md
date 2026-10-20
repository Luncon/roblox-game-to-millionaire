# Proposal

## Why

Seneca needs a first formation focused on ranged coordination without shields. The approved Focused Volley uses one melee guard, three archers and one medic, giving the army sustained concentrated fire and bounded evasive movement.

## What Changes

- Add Seneca Focused Volley at the existing settlement-20/250-coin formation gate after War Council I, Barracks Capacity II and Hospital I. Shield Training and armor prerequisites do not apply.
- Require a living 1-melee/3-ranged/1-medic roster gathered in the owned Training Yard; recruit it through the existing Barracks composition screen.
- Assemble on the road and march at the shared pace, deploying a loose archer crescent at bow range or the final center destination.
- Prioritize a shared valid enemy and stagger archer windups without increasing damage, range or individual fire rate. Allow bounded lateral/short retreat movement; the melee guard intercepts locally and returns to the group.
- Preserve stationary Hold attacks/healing, explicit Advance/Regroup cancellation and captured-life replacement rules. Losing the sole guard or every archer releases ordinary Advance unless held.
- Keep both Seneca and Japan shieldless. Existing shield factions retain their purchases, equipment, persistence and tactics.

Confirmed: shieldless Seneca, ranged emphasis, Focused Volley composition/coordination and bounded evasive movement. Implementation defaults: shared unlock price/level and march pace; 40-stud deployment, 0.45-second minimum spacing between archer windups, 8-stud archer movement bounds and 14-stud guard bounds. Japan's speed formation, Split Fire, historical reenactment, new assets and publication are outside scope.

## Capabilities

### New Capabilities

- `coordinated-ranged-formations`: shieldless ranged formation progression, composition, target focus, staggered firing and local defense.

### Modified Capabilities

None in the main inventory; existing formation change contracts remain the compatibility baseline.

## Impact

Formation definitions/coordinator, shield eligibility, profile/economy validation, battle planning and council/Barracks feedback, map markers, deterministic tests and fake-store Studio fixtures. Existing profile keys and recruitment counts are reused; no new remotes, dependencies, saved combat state or source-template edits.
