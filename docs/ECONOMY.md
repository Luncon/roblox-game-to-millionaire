# Tycoon buttons and civilization equipment

Choose one of the 13 civilizations and go to your assigned settlement. All
purchases and earning happen on real buttons on the ground. The HUD shows coins
and upgrade levels; it has no earning or purchase controls.

- **Gold coin button:** click it or use its interaction prompt for exactly one
  coin per accepted activation. Standing on it does not generate income.
- **Settlement pad:** click, interact, or walk onto it to expand the settlement.
- **Weapon pad:** buy the next civilization weapon tier independently.
- **Armor pad:** buy the next civilization armor tier independently.
- **Barracks pads:** buy faster reinforcements and eventually unlock a ranged troop.
- **Battlefield kills:** a player or troop final hit earns its civilization 10 coins.

Upgrade pads turn green when you can afford them, red when you cannot, and gray
when a preceding tier or settlement level is required, or a track is maxed.
They show prices and next equipment stats. Early settlement expansions reveal
new physical pads. Tier-two and tier-three pads retire after purchase; the
tier-four weapon and armor pads remain and buy each later tier through 50.
Keeping the same pad preserves one purchase per entry even across tier four.
Mouse, keyboard prompt,
mobile prompt, and native controller prompt are supported by the engine. Actual
hardware input verification is recorded in the playtest guide.

## Settlement expansion

| Level | Growth phase | Size | Next price |
| --- | --- | --- | --- |
| 1 | Outpost | 60 studs | 25 coins |
| 10 | Village | 96 studs | 115 coins |
| 20 | Town | 136 studs | 215 coins |
| 30 | City | 176 studs | 315 coins |
| 40 | Capital | 216 studs | 415 coins |
| 50 | Grand settlement | 256 studs | Maximum |

Every level adds four studs of width and a lasting themed feature. Architecture,
districts and landmarks depend on the civilization. Next settlement cost at
level L is `25 + 10*(L-1)`, through level 49. Reaching 50 costs 12,985 coins and
never increases income per activation. See [world and settlement growth](WORLD.md).

## Weapon and armor tiers

| Tier | Next price per track | Melee damage | Standard maximum health |
| --- | --- | --- | --- |
| 1 | 15 coins | 10 | 100 |
| 10 | 42 coins | 11.469 | 107.347 |
| 25 | 87 coins | 13.918 | 119.592 |
| 50 | Maximum | 18 | 140 |

Damage is `10 + 8*(L-1)/49`; armor health is `100 + 40*(L-1)/49`.
Each adjacent level adds about 0.1633 damage or 0.8163 health. Stats remain
fractional in combat; the displayed decimals are rounded. Ranged damage is 80%
of the same weapon stat, from 8 through 14.4, without flooring away small gains.
There are no exponential bonuses. Next gear cost is `15 + 3*(L-1)` through
level 49. Each equipment track costs 4,263 coins in total. Buying a weapon does not buy
armor or expand the settlement. Players equip themed armor and a weapon when
claiming a civilization, receive updated gear on purchase, and regain it after
character resets. Every weapon/armor level through 50 is capped by the settlement
level. Expand the settlement before buying a higher tier. Their preceding tier
is required even when a later button is visible. Barracks remains a separate
four-level track; its current prices, respawn timing and two-slot limit are
listed in [army details](ARMY.md).
Armor grants maximum health and preserves missing health. Equipped player weapons
now attack in melee; army gear updates immediately as well.

This rebalances old level-four gear: saved coins and level numbers stay intact,
but level four now uses the gradual curve rather than its previous maximum
stats. A maximum-tier melee attacker needs six hits against a standard starter;
the starter needs fourteen against maximum armor. Equal-tier fights take ten
hits at level one and eight at 50, ignoring regeneration, movement and other
attackers. These bounds are tuning checks, not proof that live combat is balanced.

Sparta uses a spear and bronze cuirass; Seneca a bow and tunic; Britain a musket
and redcoat; Mongols a sabre and lamellar armor; Vikings an axe and mail; Persia
a spear and scale cuirass; Japan a katana and do armor; Mauryan India a spear and
cuirass; Spain a rapier and breastplate; Egypt a khopesh and linen/bronze; Rome a
gladius and segmented cuirass; Ottomans a kilij and mail; Ming China a dao and
lamellar armor. Player gear and eight civilization NPCs use stylized generated models. Five melee
civilizations use the [user-provided models](../assets/README.md), preserving
clothing and headwear. No Marketplace scripts are imported.

## Saved progress and server rules

Coins and all upgrade tracks save separately for each player and civilization.
They survive character resets, civilization switches and later joins when storage
is available. **Change civ** reopens the selector and keeps your plot when you
choose a free civilization. Your old civilization retains its progress, while an
unstarted one begins at zero coins and level one. Saved progress loads before
selection; failed loads block play without replacing the record. See
[saved profiles](PROFILES.md) for autosaves, final saves, failure feedback and
Studio development isolation.

The server checks the actual player's claim, living character, and distance to
the fixed pad. There is no client earning/purchase remote. Earning allows a
20-activation burst, replenishing at 15 per second; excess requests award nothing.
A separate physical-event budget bounds malformed or foreign traffic before any
response or rendering. Purchases check funds, tier, and a per-track cooldown
before a non-yielding deduction. The contact latch prevents repeated purchases
from multiple body parts or standing on a pad. These limits do not prove input
came from a human and do not detect all autoclickers.

A profile that is loading, closing, lost or expired cannot earn coins, buy
upgrades or receive kill rewards. Temporary save failures retry while the known
lease is valid. A lost session requires rejoining to reload safely.

A final validated hostile kill awards 10 coins to its attacking civilization,
including kills by either troop class or the player. Earlier attackers receive no
assist coins. Environmental, friendly, neutral, and outside-arena deaths do not
reward. This fixed server credit does not consume coin-click tokens; duplicate
notifications cannot reward the same victim life twice. The currency cap is
one billion; a full 10-coin award is rejected if it would exceed the cap.

All 13 choices follow the [agreed roster](GAME_VISION.md); only eight can own
plots in a full server. Tuning lives in
[SettlementProgression](../src/shared/SettlementProgression.luau),
[ProgressionConfig](../src/shared/ProgressionConfig.luau),
[UpgradeTracks](../src/shared/UpgradeTracks.luau), and
[Economy](../src/server/Economy.luau).
