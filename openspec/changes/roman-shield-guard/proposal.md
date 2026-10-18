# Proposal

## Why

The player approved a second shield formation for Rome, keeping Sparta's marching speed. Testing the normal Studio build also needs a quick coin grant without loading a separate temporary-currency place.

## What Changes

- Rome gains Shield Training and Roman Shield Guard using the same level-15/20 prerequisites and prices as Sparta, three gladius shieldmen, one pilum thrower and one medic.
- The compact guard places the supports close behind the center guard and between outward-facing outer guards. Both formations march at six studs/second, release to Advance on final center arrival or a frontline casualty, and respect explicit Hold.
- Formed Roman melee may use their stationary Double Slash; ranged use ordinary throws. Shields keep two-hit, facing-based protection without replenishment or new stat bonuses.
- Select the faction's formation at its owned council table and buy its unlock beside the council. Preserve civilization-isolated version-one fields and reject foreign selections.
- Add a clearly labeled +1,000 TEST COINS physical pad beside the earning pad in the normal Studio build, with fixed server grant, living-owner/proximity/write checks and bounded activation cadence. It is absent and rejected outside Studio.

Confirmed: Roman guard composition/shape, angled shields, stationary sword skills, existing shared formation transitions, same speed, and a testing coin button in the main build. Implementation defaults: mirror Spartan progression and prices, reuse the existing inert shield asset until dedicated Roman art is supplied, and limit the testing grant to Studio. Other civilizations, overhead protection, live publication and combat stat bonuses are outside scope.

## Capabilities

### New Capabilities

- `civilization-formations`: faction-specific formation geometry, progression, council selection and shield/skill behavior, extending the existing Spartan change.
- `studio-test-currency`: a server-owned testing grant in normal Studio builds.

### Modified Capabilities

None in the main inventory; the existing army-formations and combat-shields change contracts remain the compatibility baseline, with Roman support added here.

## Impact

Formation config/coordinator, progression/profile validation/economy, council/pad UI and map markers, shared shield lifecycle/equipment and weapon skill dispatch; Studio-only world controls/economy grants. Add deterministic and fake-store Studio fixtures for Rome and grant authority. No dependencies, new persistent fields, source asset mutation or data-store key changes.
