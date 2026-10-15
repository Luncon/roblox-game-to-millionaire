# Proposal

## Why

The user added weapon and hat models in Studio to replace placeholder equipment.
Players and generated troops should wear the matching civilization gear while
the five custom melee skins retain their original headwear.

## What Changes

- Export sanitized visual copies to repository assets and map them through Rojo.
- Equip Spartan, British, Seneca and Egyptian hats on players and applicable
  generated troops. Confirmed Egypt mapping: Pharaoh for players, Anubis for troops.
- Replace matching weapon visuals: Spartan spear/shield, British officer sword,
  Japanese katana, Mauryan/Persian spear and bow users' bow.
- Preserve custom melee headwear, current stats, purchases, saves and combat authority.
- Proposed implementation uses normalized welded cosmetic clones with procedural
  fallback. New attacks, new damage rules and extra troop types are outside scope.

## Capabilities

### New Capabilities

- `civilization-equipment-visuals`: Safe civilization- and role-specific imported
  equipment that survives upgrades without replacing custom troop skins.

### Modified Capabilities

None.

## Impact

Equipment rendering, asset storage and Rojo mapping, focused equipment/rig tests,
asset documentation and Studio visual checks. No dependency or save schema changes.
