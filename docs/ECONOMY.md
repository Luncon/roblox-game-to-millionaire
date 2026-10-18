# Tycoon buttons and civilization equipment

Choose one of the 13 civilizations and go to your assigned settlement. Tycoon
earning, purchases and farm collection use real ground buttons. The HUD shows
progress; it has no earning or purchase controls.

- **Gold coin button:** click it or use its interaction prompt for exactly one
  coin per accepted activation. Standing on it does not generate income.
- **Settlement pad:** click, interact, or walk onto it to expand the settlement.
- **Weapon pad:** buy the next civilization weapon tier independently.
- **Armor pad:** buy the next civilization armor tier independently.
- **Barracks pads:** buy faster reinforcements and eventually unlock a ranged troop.
- **Building pads:** buy training, farming, army, workshop and storage improvements beside their sites.
- **Farm collection pad:** transfer the active civilization's reserved farm coins to its wallet.
- **Battlefield kills:** a player or troop final hit earns its civilization 10 coins.

Available upgrade pads turn green when affordable and red when unaffordable.
Progression-locked and completed one-time pads are absent; the main hall lists
missing milestone requirements. Weapon/armor pads sit at the armory, barracks
pads at its entrance, and building pads beside their structures or construction
sites. Eligible repeated pads retain their identity and one-purchase-per-entry
latch while labels and balances change.
While carrying an equipped weapon, use the pad's interaction prompt (E on PC)
or step on an upgrade pad. Unequip the weapon before using mouse clicks on a pad;
the equipped Tool consumes those clicks. Mouse, keyboard prompt,
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
level L is `25 + 10*(L-1)`, through level 49. Settlement purchases alone total
12,985 coins; the required settlement-10 buildings add 445 coins, for 13,430
combined. Settlement size never increases coin-button income. See
[world and settlement growth](WORLD.md). These prices do not establish measured
30–45 minute or endgame pacing.

## Useful buildings through settlement 16

| Building | Required settlement | One-time price | Additional requirement | Effect |
| --- | ---: | ---: | --- | --- |
| Training Yard I | 5 | 50 coins | None | Unlocks advance, hold and regroup army orders |
| Farm I | 7 | 80 coins | None | Produces one reserved coin per five active seconds |
| Worker Camp I | 7 | 60 coins | Farm I | Adds a second farmer and one coin per production interval |
| Army Camp I | 10 | 120 coins | Barracks IV | Adds one selectable melee/ranged reinforcement slot |
| Farm II | 12 | 180 coins | Farm I | Adds one coin per production interval and improves the fields |
| Worker Camp II | 12 | 140 coins | Worker Camp I and Farm II | Adds a third visible farmer and one coin per interval |
| Blacksmith I | 13 | 150 coins | None | Reduces weapon purchase prices by 5%, rounded upward |
| Armorer I | 13 | 150 coins | None | Reduces armor purchase prices by 5%, rounded upward |
| Storehouse I | 16 | 140 coins | Farm I | Raises farm reserve capacity from 60 to 180 |

Purchases complete immediately and save separately per civilization. Entering
settlement 10 from level 9 requires **Barracks IV, Training Yard I, Farm I and
Worker Camp I**. Their combined cost remains 445 coins, including the first three barracks
purchases. Existing saved settlements already at 10–50 retain their level
without retroactive building requirements. No later settlement checkpoint is
enforced in this milestone.

The army camp choice defaults to melee and saves as `warrior` or `ranged`.
Changing it takes effect at the next camp-slot spawn; it does not heal or replace
a living troop or restart a pending countdown. Actual class changes have a
separate 0.4-second cooldown; selecting the current class is a no-op.

## Active farming and collection

An owned farm produces `farmLevel + workersLevel` coins every five seconds into
a reserve, rather than directly into the wallet. Farm I alone earns one; Farm I
and Worker Camp I earn two; Farm II with Worker Camp I earns three; both tier II
buildings earn four. The reserve holds 60 coins, or 180 with Storehouse I, and
stops earning at capacity. Visible passive workers tend the fields without
participating in combat.

Only the currently selected, writable civilization earns farm income. Clock
state is local to its live account: joining, reopening or switching resets the
clock, so offline time and inactive civilizations never earn. Switching discards
an unfinished interval. Buying Farm I starts its clock at purchase. Every farm,
worker or storehouse purchase settles completed intervals at the previous yield
and capacity, then resets the unfinished interval. Expanding a full reserve
leaves its existing 60 coins intact and starts a fresh interval; it never credits
time spent full. Full reserves and lost profile authority discard blocked time
rather than banking a later burst.

The owner's collection pad transfers each reserved coin once. If the billion-coin
wallet cap leaves room for only part of the reserve, the remainder stays in the
farm. Empty or full-wallet collection changes neither balance. Collecting from
a previously full reserve restarts its interval so time spent full is not earned
retroactively. Farm production, collection and troop selection follow the same
writable-profile guard as other economy mutations.

## Weapon and armor tiers

| Tier | Base next price per track | Melee damage | Standard maximum health |
| --- | --- | --- | --- |
| 1 | 15 coins | 10 | 100 |
| 10 | 42 coins | 11.469 | 107.347 |
| 25 | 87 coins | 13.918 | 119.592 |
| 50 | Maximum | 18 | 140 |

Damage is `10 + 8*(L-1)/49`; armor health is `100 + 40*(L-1)/49`.
Each adjacent level adds about 0.1633 damage or 0.8163 health. Stats remain
fractional in combat; the displayed decimals are rounded. Ranged damage is 80%
of the same weapon stat, from 8 through 14.4, without flooring away small gains.
There are no exponential bonuses. Base next gear cost is `15 + 3*(L-1)` through
level 49. Each equipment track costs 4,263 coins in total before discounts.
Blacksmith I applies only to weapon purchases; Armorer I applies only to armor.
Their final price is `ceil(baseCost * 0.95)`: a 42-coin tier becomes 40 coins.
Owning the respective workshop before all 49 purchases makes that track total
4,074 coins. Workshops change prices without adding damage or health; pads, HUD
and server charges use the same final offer. Buying a weapon does not buy
armor or expand the settlement. Players equip themed armor and a weapon when
claiming a civilization, receive updated gear on purchase, and regain it after
character resets. Every weapon/armor level through 50 is capped by the settlement
level. Expand the settlement before buying a higher tier. Their preceding tier
is required even when a later button is visible. Barracks is a separate
six-level track; its current prices, respawn timing and original two-slot capacity are
listed in [army details](ARMY.md).
Armor grants maximum health and preserves missing health. Equipped player weapons
now attack in melee; army gear updates immediately as well.

This rebalances old level-four gear: saved coins and level numbers stay intact,
but level four now uses the gradual curve rather than its previous maximum
stats. A maximum-tier melee attacker needs six hits against a standard starter;
the starter needs fourteen against maximum armor. Equal-tier fights take ten
hits at level one and eight at 50, ignoring regeneration, movement and other
attackers. These bounds are tuning checks, not proof that live combat is balanced.

Sparta uses a spear and bronze cuirass; Seneca a bow and tunic; Britain an officer sword
and redcoat; Mongols a sabre and lamellar armor; Vikings an axe and mail; Persia
a spear and scale cuirass; Japan a katana and do armor; Mauryan India a spear and
cuirass; Spain a rapier and breastplate; Egypt a khopesh and linen/bronze; Rome a
gladius and segmented cuirass; Ottomans a kilij and mail; Ming China a dao and
lamellar armor. Players and generated troops wear matching outfits; five melee
civilizations use the [user-provided models](../assets/README.md), preserving
clothing and headwear. Imported appearance does not supply combat stats or scripts.

## Saved progress and server rules

Coins and all upgrade tracks save separately for each player and civilization.
They survive character resets, civilization switches and later joins when storage
is available. **Change civ** reopens the selector and keeps your plot when you
choose a free civilization. Your old civilization retains its progress, while an
unstarted one begins at zero coins, level-one original tracks, unowned new
buildings and an empty farm reserve. Saved progress loads before
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
upgrades, produce/collect farm coins, change troop choice or receive kill rewards.
Temporary save failures retry while the known
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
[UpgradeTracks](../src/shared/UpgradeTracks.luau),
[SettlementDevelopment](../src/shared/SettlementDevelopment.luau), and
[Economy](../src/server/Economy.luau).

The expansion's fresh single-window Studio run passed 209 module cases and five
native purchase, production, collection, restoration and replacement checks
against injected fake profiles. Executed runtime evidence and remaining limits belong in
[playtest records](PLAYTEST.md).

## Weapon skill purchases

A next-tier skill pad beside the training camp offers tiers I–V at weapon
levels 10/20/30/40/50 for 100/200/350/550/800 coins, respectively. Training
Yard I is required. All five purchases total 2,000 coins; workshop discounts
apply only to their original gear tracks. Eligibility does not grant a tier for
free. The pad is absent while progression-locked or completed and uses existing
ownership, funds, writable-profile and one-purchase-per-entry guards.

Each civilization saves one skillLevel shared by its eligible players and troops.
Purchases do not heal or reset attacks, cooldowns or troop replacement deadlines.
See [weapon skills](WEAPON_SKILLS.md) for damage, cooldowns and controls. Runtime
acceptance of this new purchase path remains pending in [PLAYTEST.md](PLAYTEST.md).

Hospital I costs 200 coins at settlement 10 and requires purchased Training Yard
I. Army Camp is optional. It adds one separate medic slot, for up to four troops before Army Camp II (five with II),
and enables recovery in the owned training yard. Workshops do not discount this
purchase. The existing guarded physical-pad flow handles the charge; buying it
does not replace or heal living fighters or change pending respawn deadlines.

## Shields, army expansion and planning

Army Camp II costs 250 coins at settlement 18 after Army Camp I and Barracks VI.
It adds a dedicated melee slot while preserving the existing camp class choice.
War Council I costs 200 at settlement 19 after Training Yard I, for every
civilization. Its accessible map room sits beside the training camp.

Sparta, Rome and Persia offer Shield Training I for 150 at settlement/armor 15 after
Armorer I. Each faction formation (Spartan Shieldwall, Roman Shield Guard or
Persian Archer Screen) costs 250 at settlement 20
after that shield training,
War Council I, Army Camp II and Hospital I. Purchases use physical pads and
receive no workshop discount. The council table selects a purchased formation;
selection costs no coins. Unlocks and selection save separately per civilization.
Existing level-20+ settlements receive no retroactive checkpoint requirements.

The normal Studio build also provides a purple +1,000 TEST COINS pad beside the
single-coin pad. Only the nearby living owner with writable progress can receive
a fixed 1,000-coin grant, at most once per half second and within the normal
balance cap. It affects the active civilization and uses normal StudioDevelopment
saving; the separate temporary-coin test build still uses fake storage. Testing
pads and grants are disabled outside Studio.

Purchased shield training also provides a rack beside camp. Recalled melee can
replace a fully spent shield there without a coin charge; partial shields are
preserved. This restores transient charges only and adds no saved field.
