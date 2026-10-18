# Proposal

## Why

The player approved a Persian Archer Screen that fights from a protected firing position. A new shape alone would repeat the existing Spartan arc; stopping for archery and limiting shieldmen to local defense creates a distinct tactical role.

## What Changes

- Persia gains the same shield training, formation prerequisites and prices as Sparta/Rome, with three spear/shield melee, one existing Persian archer and one medic.
- The council selects Persian Archer Screen. A complete camp muster assembles on the road and marches at the existing six-stud pace, using a straight three-man line with the archer/medic behind it.
- A clear hostile bow opportunity deploys the screen before the center. Deployed shieldmen defend a small area around their slots, the archer fires ordinary arrows and the medic heals/avoids danger behind the line.
- The screen stays deployed after its target disappears, and also deploys at the final destination when no shot occurs en route. Advance/Regroup cancel it; frontline casualties resume Advance, explicit Hold remains stationary and authority loss stops it. Captured support-loss/replacement rules remain shared.
- Add a visible shared shield rack near training after shield unlock. Recalled melee with zero remaining shield charges physically collect a new shield before returning to camp; partially intact shields stay unchanged.
- Preserve stationary front-line spear skills and two-hit shields, faction-isolated saved selection and unchanged combat authority.

Confirmed: Persia, straight protective line, rear archer/medic, firing-range deployment and local melee defense. Defaults: match existing unlocks/costs/speed/shield art; stop at 40 studs within the normal 45-stud bow range; defend within six studs of each front slot; latch deployment until command/frontline loss rather than oscillating with target movement. The user also explicitly requested shared troop shield resupply on recall. No new troop types, imported assets, stat bonuses, live publication, save keys or changes to Spartan/Roman formation tactics.

## Capabilities

### New Capabilities

- `archer-screen-formations`: faction-gated Persian progression, bow-range deployment, bounded frontline defense and shared lifecycle/command authority.
- `shield-resupply`: visible unlocked shield racks and server-validated regroup pickup of spent troop shields for every supported shield civilization.

### Modified Capabilities

None in the main inventory. Existing Spartan and Roman change contracts remain the compatibility baseline.

## Impact

FormationConfig/ArmyFormation, WarriorService and bounded encounter planning; faction-aware council/pad/profile/shield code reuses definitions. Add logic and fake-store Studio checks plus documentation. No dependencies, persistent field additions or data-store changes.
