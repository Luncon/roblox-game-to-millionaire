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
when a preceding tier is required or the permanent settlement pad is maxed. They
show prices. Each settlement expansion adds actual new floor buttons. Purchased
tier buttons disappear. Walk-on input makes one purchase per entry; later tiers
have their own separate pads. Mouse, keyboard prompt,
mobile prompt, and native controller prompt are supported by the engine. Actual
hardware input verification is recorded in the playtest guide.

## Settlement expansion

| Level | Settlement | Size | Next price |
| --- | --- | --- | --- |
| 1 | Outpost | 60 studs | 25 coins |
| 2 | Village | 68 studs | 75 coins |
| 3 | Town | 76 studs | 150 coins |
| 4 | Citadel | 84 studs | Maximum |

Expansion adds buildings and perimeter structures. Reaching the Citadel costs
250 coins in total and never increases income per activation.

## Weapon and armor tiers

| Tier | Name | Next price per track | Weapon damage setting | Maximum health on a standard avatar |
| --- | --- | --- | --- | --- |
| 1 | Recruit | 15 coins | 10 | 100 |
| 2 | Veteran | 50 coins | 14 | 115 |
| 3 | Elite | 125 coins | 19 | 135 |
| 4 | Champion | Maximum | 25 | 170 |

Each equipment track costs 190 coins in total. Buying a weapon does not buy
armor or expand the settlement. Players equip themed armor and a weapon when
claiming a civilization, receive updated gear on purchase, and regain it after
character resets. Weapon/armor tiers 2, 3, and 4 unlock at settlement stages
2, 3, and 4. Every upgrade level is capped by the settlement level. Expand the
settlement before buying a higher tier. Their preceding tier is required even when a later button is visible.
Armor grants maximum health and preserves missing health. Equipped player weapons
now attack in melee; army gear updates immediately as well.

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
[UpgradeTracks](../src/shared/UpgradeTracks.luau), and
[Economy](../src/server/Economy.luau).
