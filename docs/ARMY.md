# Barracks, troops, and player combat

Settlement stage 2 unlocks a level-one barracks and deploys one free melee warrior.
It walks into the battlefield and attacks enemy troops and claimed enemy players.
Upgrade the barracks through its newly unlocked ground buttons:

| Barracks | Required settlement for purchase | Price | Respawn delay | Living troop capacity |
| --- | --- | ---: | ---: | --- |
| I | 2 (automatic unlock) | Free | 15 seconds | One melee |
| II | 2 | 30 coins | 14.5 seconds | One melee |
| III | 3 | 75 coins | 14 seconds | One melee |
| IV | 4 | 150 coins | 13.5 seconds | One melee + one ranged |

Each paid upgrade reduces future respawn waits by 0.5 seconds. At level IV, the
ranged troop deploys automatically alongside the warrior. Each class has its own
replacement countdown. A purchase does not shorten a countdown already running,
replace a living unit, or create an extra unit. The HUD shows both slots.

Weapon and armor pads upgrade the player and both troop classes immediately.
Armor preserves missing health; weapon upgrades do not heal. Replacements use
the latest gear. Melee damage tiers are 10/14/19/25, and maximum health tiers are
100/115/135/170. Ranged damage is 80% of the weapon tier, rounded down: 8/11/15/20.
Damage, armor, prices and barracks timing come from shared UpgradeTracks; ranged
styles and flight tuning come from RangedConfig.

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
countdowns. Leaving removes both classes, corpses and in-flight shots, and cancels
replacements. Corpses last three seconds. The server controls damage, rewards,
NPC physics and timers. Progress remains session-only. Saving, formations,
additional troop slots, recruitment choices and ranged player attacks are planned.

## Custom melee models

Sparta, Britain, Japan, Seneca and Maurya now use the five user-provided R6 models in [the asset catalog](../assets/README.md). Their original clothes and headwear are retained; upgrades add tier gear and change the shared combat stats. Other civilizations and ranged troops keep their generated models. The Studio reference models remain untouched.
