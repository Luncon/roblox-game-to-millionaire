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
It adds one independent reinforcement slot, bringing the fighting army to three troops; Hospital I can add a separate medic.
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
- **Regroup:** cancel in-flight shots and walk to the exterior campfire training
  yard without pursuing or attacking enemies. After arrival, troops stroll
  slowly around the fire at speed 5, pausing for 2–5 seconds between walks.
  They stay inside the yard and clear of the decorative fire. Blocked walks
  retry in the other direction; troops never teleport to resting positions.
  Advance restores normal speed 12 and battlefield movement. Hold stops the
  current stroll and retains that position. Repeating Regroup preserves the
  ongoing rest cycle.

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
its ranged troop retains the musket. Spartan shields require Shield Training I and block two frontal hits per life;
they do not increase armor health. See [the asset assignments](../assets/README.md#imported-equipment-visuals)
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
cooldown. Marching speed remains 12; close melee footwork slows to 6 and ranged
retreats use speed 8.

Owned troops and neutral opponents share encounter coordination. Advancing melee
troops take separate four-stud approach positions around an enemy, wait outside
reach when all six positions are occupied, and walk apart before pursuit if
bodies overlap. Nearby separation uses walking, not teleporting or physical
pushing. Troops retain valid targets through small distance changes, consider
crowding and favor threats close to friendly ranged troops when choosing an
opponent. Pathfinding handles travel; supported, obstacle-checked local steps
handle nearby encounters.

All owned and neutral navigators share soft spacing during Advance, Regroup,
combat steps and camp strolls. They look ahead for allied and enemy bodies,
choose checked passing steps or yield in place; held troops remain obstacles.
A yield does not trigger the stuck-jump watchdog. Detours preserve terrain,
water and obstacle checks. Four staggered camp arrival points fit through the
training gate; inside, detours stay in the yard and clear of the fire.
Noncolliding bodies can still briefly intersect during changing traffic.

Without a target, fighters occasionally shuffle one or two studs around their
rally point and shift their weight while standing. After contact, melee fighters
sometimes take short arcs or diagonal pressure/yield steps, with varied pauses
and directions, keeping a 3.5–4.5 stud distance from the opponent. These optional
steps run at speed 4 and end before the next windup. Windup, contact, weapon
skills and Hold stay planted. Contacts, damage and attack cooldowns are unchanged.
Medical range limits still constrain fighter footwork; medic healing and enemy
avoidance retain priority over optional movement.

Ranged troops prefer a 22–35 stud firing distance. Hostile melee inside 12 studs
triggers slower backward or diagonal steps, with sideways alternatives at the
arena edge, stopping when safe at 18 studs or
after an 18-stud/three-second retreat episode. Changing firing targets cannot
renew that episode. Blocked shots prompt short sideways searches for a clear
line of sight. Ranged troops remain catchable and stand still while aiming
and releasing. Between shots they sometimes take short lateral steps at speed
5, with pauses and changes of direction. Hold permits stationary attacks only.

Melee cycles wind up for 0.2 seconds, contact for 0.15 and recover for 0.65.
Ranged cycles use 0.35/0.15/1.5 seconds. The weapon reaches its strike pose at
contact; one server contact attempt applies normal melee damage or releases
one normal projectile. Moving out of reach, obstructing sight, leaving the
arena or losing authority can make the pending attack miss. Targets stay locked
through the swing. Cancelled attacks consume their cadence, and Regroup cancels
pending contacts and in-flight shots before returning to camp.

Spears thrust, swords slash, axes chop, bows draw and release, and firearms or
crossbows aim and recover. Imported R6 rest orientations and source skins stay
intact. Accepted hits briefly recoil and flash; these effects add no damage or
stun. Poses and movement are controlled by the server. Encounter state is transient
and clears on death, orders, civilization switching and teardown.

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
civilization's eligible troops. See [saved profiles](PROFILES.md). Hospital medics
and Army Camp II provide the fourth/fifth slots. The first Spartan formation is
tracked in the active `spartan-shieldwall` change; other formations, specialist
recruitment and ranged player attacks remain planned.

## Custom melee models

Sparta, Britain, Japan, Seneca and Maurya use the five user-provided R6 models in
[the asset catalog](../assets/README.md). Their original clothes and headwear are
retained; upgrades add tier gear and change the shared combat stats. Other
civilizations and ranged troops keep their generated rigs and wear the matching
outfits. The Studio reference models remain untouched.

## Weapon-family skills

Players and owned troops gain paid weapon skills through the training-camp pad:
spear/javelin Dash Thrust (8s cooldown), axe Whirlwind (12s), and sword Double
Slash (9s). Tiers I–V require weapon levels 10/20/30/40/50. NPCs activate
skills automatically; players use **R**, gamepad **Y**, or the touch skill button.
Ranged spear/axe roles use the same skill at close range with their ordinary 0.8
role damage multiplier. Hold prevents dashing; Regroup cancels pending skills.
Neutral opponents and unsupported weapon families do not receive skills.

Skills replace ordinary attacks only during their active animation, with immediate startup and no recovery pause, with no stun,
invulnerability or healing. Source rigs, grips and clothing are preserved. The
server validates every contact and consumes each victim-life kill reward once.
See [the full damage/price tables and controls](WEAPON_SKILLS.md). Solo Studio
checks passed; multiplayer, additional input-device and published-client checks
remain pending. See [playtest evidence](PLAYTEST.md).

## Hospital support and recovery

Hospital I (settlement 10, Training Yard I, 200 coins) deploys one dedicated
medic. It does not consume the Army Camp selection: barracks melee/ranged, camp
reinforcement and hospital medic can coexist. `MedicCount` and
`MedicRespawnAt` are separate; total army count includes support. The medic uses
a fixed 15-second replacement wait. Barracks purchases retain existing deadlines.
Owner armor applies while preserving missing health; weapon upgrades never scale
healing. Medics use civilization outfits, the NPC palette/face and an original
bandage satchel. They are targetable enemies but cannot attack or use skills.

| Order | Fighters | Medic |
| --- | --- | --- |
| Advance | Fight normally; at 20% health stay in medic healing range until 40% | Head directly to the battlefield, then support the living army average; heal injured troops while moving and avoid enemies |
| Hold | Stay in place; attack enemies already in reach | Stay in place; heal patients already within range |
| Regroup | Return to the owned training camp and rest | Cancel field bandages, return to a separate camp arrival point and rest |

The medic heads directly to the battlefield during Advance. Once inside it,
support positioning uses the average of living owned melee/ranged troops already
inside the battlefield, in the active civilization and plot. Troops still
outside do not affect that average or its healing-coverage scoring. Each joins
the average as it arrives, without waiting for other replacements. Clear positions near that average favor
covering more fighters within the 45-stud bandage radius before minimizing
travel. It does not follow a single escort or choose a new movement goal for every injured patient. Bandage
selection runs independently, so casts do not stop travel or repeatedly turn a
moving medic toward the patient.

Ordinary support goals stay level with or ahead of the medic along its owner's
approach to the battlefield. Rearward troop averages, deaths, missing patients
and fresh replacements cannot send it back to barracks. A rearward average can
be approached laterally; otherwise the medic holds its current field position.
With no fighters on the battlefield it continues toward the battlefield center
if still ahead, even while living replacements approach from outside. Healing
eligibility remains independent and can include approaching troops in range.
Widely separated troops cannot all remain in healing range under this rule.

Only an actual enemy or Regroup may cause backward travel. Enemies within 18
studs prompt checked 10-stud avoidance steps that increase the distance to the
nearest threat. There is no retreat episode, origin, duration or three-second
stop. The next normal movement leg also checks enemy clearance, preventing an
immediate return into the same danger. Hold remains stationary.
While fleeing, the medic slightly favors routes toward wounded owned fighters
already on the battlefield. It can start curving around a pursuer even when the
first step cannot bring it closer to those allies. The preference permits at
most two studs less endpoint clearance than the safest available route; the
whole leg must still avoid moving closer to an already-near enemy or entering
the 18-stud band of a farther enemy. With no eligible wounded allies it chooses
the route with the most clearance. Bandages continue during the escape.

During Advance a fighter at or below 20% health keeps a living owned medic within
visible 45-stud healing range until reaching 40% health. It continues ordinary
melee/ranged attacks and can pursue inside that radius. It closes toward a safe
position about 40 studs from the medic only when outside range or sight. It does
not retreat farther when already in range or wait defensively for heals. Pending
contacts, launched shots and cooldowns retain their ordinary behavior. Automatic
spear dashes pause while range-limited; stationary skills remain available.
Missing medics, changed orders, lost authority and new lives clear support state.
Hold stays stationary and Regroup retains yard return.

Bandages restore up to 12 HP, have a 45-stud range and a three-second launch
cooldown. Lowest health fraction wins, then greatest deficit, distance and stable
slot identity among visible, currently registered patients. A blocked or obsolete
critical patient cannot prevent healing another eligible troop. One visible arced
flight per medic uses native sphere sweeps and a three-stud proximity radius.
It heals one nearest eligible wounded troop along the swept path, including a
near miss of a moving patient. It can catch a different nearby owned troop, but
only a life registered at launch. Walls block contact-to-patient healing as well
as source visibility. Distant misses, replaced lives and expiry cannot heal.
Launch spends cooldown
including misses; cancellation, replacement and civilization switches preserve
the owner's medic-slot deadline within the server. Regroup, death, departure,
lost write authority and teardown cancel pending work. No self-bandaging, player,
foreign-owner, neutral or passive worker healing occurs. No healing rewards or
attack procs are awarded.

Hospital ownership also enables five HP per second inside the owned training
yard after two continuous undamaged seconds. Actual plot-local position and root
height govern eligibility, independently of order and medic survival. Hold inside
works; leaving, damage, full health, a stalled update or lost authority resets the
wait. No offline, inactive or missed-frame healing accumulates. Healing clamps to
current MaxHealth and never revives. Health bars and a brief green flash show
successful healing; the `Recovering` attribute ends at full health. Deterministic and isolated native checks are recorded in PLAYTEST.md;
two-owner replication and real-storage restoration are separate acceptance checks.
The HUD identifies the hospital medic on its own line with its independent
countdown. Short landscape layouts place army orders beside settlement status;
narrow layouts retain space between status, commands and the skill button.

### Shieldwall implementation milestone (October 18, 2026)

Army Camp II adds an independent fixed melee life, bringing the maximum to five
with the ranged barracks slot, selectable camp slot and hospital medic. Existing
health, class choices and pending respawn deadlines survive the purchase. Camp
returns use exterior navmesh goals and commit to the short crossing into the yard.

Purchased Spartan Shield Training equips the same shield asset on players and
melee troops. Each of two accepted frontal contacts in a 120-degree arc blocks
damage and spends a charge; the second removes the visual. Side/rear attacks
bypass it. Ordinary and skill contacts share this rule. Rejected contacts and
ForceFields preserve charges. Equipment rebuilds, upgrades and same-life
civilization switches cannot refill it; fresh lives receive two charges.

To deploy Spartan Shieldwall, buy its unlocks and use the owned War Council map
table (click, E/touch interaction or controller prompt) to select it. Use Regroup
and wait for all five living troops in the training camp: three melee, one ranged
and one medic. The selectable camp slot must currently be melee; changing its
choice applies only at the next life. Press March Formation. The group gathers
at the road center outside the settlement before advancing at six studs/second.
The center shieldman leads the outer two by two studs; ranged and medic follow
side by side nine studs behind the outer frontmen (`(:` when marching left).

The march waits for slow/attacking members. Formed fighters attack in place;
medics keep throwing bandages and can avoid enemies. Optional independent
footwork and spear dashes stay suppressed. Hold stops the march but permits
attacks/healing. Advance immediately abandons the formation for normal combat;
Regroup returns to camp. A casualty holds survivors and never enrolls the
replacement automatically. Starting again requires a fresh full camp muster.
Selection remains saved after cancellation; live phases, health and positions
do not. No formation combat-stat bonus is granted.
