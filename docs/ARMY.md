# Barracks, troops, and player combat

The prototype's neutral test opposition consists of two generic melee fighters
and one generic archer near the battlefield center. Every claimed civilization's
players and troops can fight them. They are friendly to one another and cannot
damage unclaimed players or actors outside the arena. Their basic stats are
100 health, 10 melee damage or 8 ranged damage, with the normal reach and attack
cooldowns. Valid final hits give the usual 10 coins to the attacking owner.

Each neutral slot replaces its dead fighter independently ten seconds after
death. Neutral fighters return toward their center positions when idle. They
have no civilization, plot or saved progression and ignore owner army orders,
upgrades and switches. Set `enabled=false` in
`src/shared/NeutralOpponentConfig.luau` to disable them on the next server start.

Settlement stage 2 unlocks a level-one barracks and deploys one free melee warrior.
It walks into the battlefield and attacks enemy troops and claimed enemy players.
Upgrade the barracks through its newly unlocked ground buttons:

| Barracks | Required settlement for purchase | Price | Respawn delay | Living troop capacity |
| --- | --- | ---: | ---: | --- |
| I | 2 (automatic unlock) | Free | 15 seconds | One melee |
| II | 2 | 30 coins | 14.5 seconds | One melee |
| III | 3 | 75 coins | 14 seconds | One melee |
| IV | 4 | 150 coins | 13.5 seconds | One melee + one ranged |
| V | 8 | 200 coins | 13 seconds | One melee + one ranged |
| VI | 14 | 300 coins | 12.5 seconds | One melee + one ranged |

Each paid upgrade reduces future respawn waits by 0.5 seconds. At level IV, the
ranged troop deploys automatically alongside the warrior. Each slot has its own
replacement countdown. A purchase does not shorten a countdown already running,
replace a living unit, or create an extra unit. Tiers V and VI keep the two
barracks slots; only future deaths receive their shorter delay. Living identities,
health, classes, orders and pending deadlines survive these purchases. The HUD
shows each available slot.

Army Camp I is available at settlement 10 with Barracks IV or higher and costs 120 coins.
It adds one independent reinforcement slot, bringing the army to three troops.
Choose melee or ranged for this camp slot. The choice saves for each civilization
and applies at its next spawn: a living troop retains its class and health, and
changing the choice never resets a pending replacement countdown. The original
melee and ranged slots remain unchanged. Each camp replacement receives the
latest owner gear and uses the barracks respawn delay in effect when it died.

Training Yard I is available at settlement 5 and costs 50 coins. It unlocks
three army orders for the living owner:

- **Advance:** march toward the battlefield and engage enemies automatically.
- **Hold:** stop pursuing enemies and attack only those already within the
  troop's normal attack range. Troops retain their current positions.
- **Regroup:** cancel in-flight shots and return to the protected home rally
  without pursuing or attacking enemies. Troops remain regrouped until ordered
  to advance or hold.

New replacements inherit the current order. Orders remain active through owner
character resets and gear upgrades, then reset to Advance when switching
civilizations or rejoining. Orders require a writable profile and are limited
on the server; clients cannot choose arbitrary movement destinations.

Weapon and armor pads upgrade the player and both troop classes immediately.
Armor preserves missing health; weapon upgrades do not heal. Replacements use
the latest gear. Fifty gradual weapon levels span 10–18 melee damage, and fifty
armor levels span 100–140 standard maximum health. Ranged damage is 80% of the
weapon stat, from 8 through 14.4; fractional gains are preserved. Each gear
level is capped by settlement level. Barracks has six levels and a maximum
of two troops from the barracks, plus one from Army Camp I. See
[the balance curve](ECONOMY.md).
Damage, armor, prices and barracks timing come from shared UpgradeTracks; ranged
styles and flight tuning come from RangedConfig.
Blacksmith I and Armorer I at settlement 13 independently discount the respective
gear purchase prices by 5%, rounded upward. They add no damage, health or troop
slots. Final purchase prices come from SettlementDevelopment offers.

Generated melee and ranged troops have rounded classic Roblox heads. Custom
melee skins retain their existing head meshes and proportions. All live NPC
clones, including the five custom melee skins, receive their civilization's
natural skin-tone art default and one front warrior face after equipment is
applied. TroopAppearance uses texture `10526794`, reused from the user's Seneca
expression, and keeps NPC BodyColors fields and body-part colors consistent.
These palettes are prototype art choices, not uniform historical skin tones.
Head dimensions, neck joints, clothes and headwear remain intact. Skin baked
into clothing textures is retained. Players keep the separate avatar wardrobe
path and do not receive this NPC tint/face override.

Thirteen outfit templates dress players and generated troops, and nineteen
equipment templates cover every current weapon role. The five custom melee
skins retain their original headwear and clothes. Other outfits combine
free Creator Store garments/cosmetics with derived copies of the user skins.
The looks are approximate historical themes fitted to existing R6 troops and
R15 players. Egyptian players wear Pharaoh headwear, while Egyptian
troops wear Anubis headwear. Britain’s player/melee weapon is the officer sword;
its ranged troop retains the musket. Spartan shields are cosmetic and do not
grant extra armor. See [the asset assignments](../assets/README.md#imported-equipment-visuals)
and [marketplace provenance](MARKETPLACE_ASSETS.md) for source IDs and dated free-price
checks. Safe visual-only clones attach to the server-generated
equipment and follow upgrades, respawns and switches without changing combat
stats or saved progression. Missing templates retain procedural visuals.

Player uniforms preserve their original clothing instances and restore affected
fields when cleared. Later external wardrobe edits become the restore baseline;
destroyed originals are not recreated and unrelated avatar items are retained.
Late native avatar appearance loading reapplies the outfit without clearing its
baseline. Headwear precedence avoids layering imported hats over outfit head
pieces, and generated tier details leave the uniform visible.

| Civilization | Ranged troop weapon |
| --- | --- |
| Sparta | Javelin |
| Britain | Musket |
| Seneca | Bow |
| Mongols | Bow |
| Vikings | Throwing axe |
| Persia | Bow |
| Japan | Yumi bow |
| Mauryan India | Bow |
| Spain | Crossbow |
| Ancient Egypt | Sling |
| Rome | Pilum |
| Ottomans | Musket |
| Ming China | Crossbow |

Ranged troops fire visible projectiles up to 45 studs with a two-second firing
cooldown. Shots travel in a fixed direction and can miss a moving target. Server
raycasts check the flight path; walls and protected actors stop shots. Shots are
removed on impact, range/lifetime expiry, or the shooter's death/departure.
The impact damage cooldown is also two seconds, so varying flight times can make
some successive shots deal no damage. Melee reach is five studs with a one-second
cooldown. NPC movement speed remains 12.

Equip your civilization weapon and activate it (click/tap, or the tool's normal
controller action) to strike a nearby enemy in front. Player weapons currently
use melee even for bow or musket skins. Both actors must be inside the arena,
and attacks require line of sight. Your civilization's final hit on an enemy
player or troop earns 10 coins; earlier attackers get no assist reward. Owners,
friendly units, unclaimed players and characters outside the arena are protected.

Character resets and settlement rebuilding preserve the army and its pending
countdowns. Leaving removes every troop slot, corpses and in-flight shots, and cancels
replacements. Corpses last three seconds. The server controls damage, rewards,
NPC physics and timers. Settlement, weapon, armor, barracks and infrastructure
purchases, plus the camp class choice, save for each civilization. Returning to
a saved civilization rebuilds its army from those levels; troop health,
locations, orders and pending countdowns are not persisted.
Switching removes the old civilization's units and deploys the selected
civilization's eligible troops. See [saved profiles](PROFILES.md). Formations,
fourth/fifth troop slots, specialist recruitment and ranged player attacks are planned.

## Custom melee models

Sparta, Britain, Japan, Seneca and Maurya use the five user-provided R6 models in
[the asset catalog](../assets/README.md). Their original clothes and headwear are
retained; upgrades add tier gear and change the shared combat stats. Other
civilizations and ranged troops keep their generated rigs and wear the matching
outfits. The Studio reference models remain untouched.
