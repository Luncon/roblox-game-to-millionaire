# Proposal

## Why

Combat currently provides no currency, player weapons cannot attack, all gear
tiers share the same floor pads, and barracks stop at one melee troop. Connect
combat and settlement growth with new physical upgrades and a second troop class.

## What Changes

- Soften shared weapon tiers to 10/14/19/25 damage and armor to
  100/115/135/170 health. These are proposed balancing values for the requested nerf.
- Award the attacking civilization 10 coins for a hostile NPC or player kill
  caused by its player's or troop's final validated hit. Final-hit credit was confirmed.
- Add basic player melee attacks, as confirmed, using the equipped civilization
  weapon and existing arena protections. Clients cannot choose damage or rewards.
- Create actual new ground pads as settlement stages unlock new upgrade tiers.
  Weapon/armor tiers 2, 3, and 4 require settlement stages 2, 3, and 4.
- Add three paid barracks upgrades, confirmed to require settlement stages 2,
  3, and 4. Each subtracts 0.5 seconds from future respawns: 14.5, 14, 13.5.
  Proposed prices are 30, 75, and 150 coins. Existing death deadlines remain intact.
- Barracks level 4 automatically adds one ranged troop alongside the melee
  warrior. Each has independent replacement state and inherits owner gear.
- Give all 13 civilizations appropriate ranged equipment and visible server
  projectiles. Initial proposed range is 45 studs and attack cooldown is 2 seconds.

- Use the five user-placed R6 models as civilization melee templates for Sparta,
  Britain, Japan, Seneca, and Maurya; preserve clothing and original placed models.

- Cap every upgrade track at the current settlement level, as requested.
  A level-one outpost offers only earning and settlement expansion.
- Replace claimed plots' freestanding identity signs with civilization-specific
  nameplates incorporated into the main building facade.

## Capabilities

### New Capabilities

- `combat-rewards`: server-authoritative final-hit currency and duplicate prevention.
- `player-melee`: equipped player attacks with ownership, range, and arena protection.
- `upgrade-unlocks`: settlement-gated physical tier pads and softened shared gear.
- `army-progression`: paid barracks timing upgrades and a civilization ranged slot.

### Modified Capabilities

None in the main spec inventory. This extends the implemented in-flight economy
and barracks changes while retaining their ownership and lifecycle guarantees.

## Impact

Shared progression/configuration, economy and pads, character equipment and rigs,
central combat/rewards, player input, autonomous army/projectiles, HUD, tests and
documentation. Progress remains session-only. Saving, formations, ranged player
weapons, extra troop slots beyond two, new civilizations, and eight-client load
testing are outside this change.
