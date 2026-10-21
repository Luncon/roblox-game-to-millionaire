# Civilization Battlefield: game direction

## Miniature redesign direction — October 20, 2026

The user has chosen a new direction inspired by Mini War: normal-sized players
build and trade while miniature civilization armies handle all fighting.
The intended economy includes placeable buildings, workers, goods, personal
restocking shops, selling, research and conquest. A shared Black Market is deferred.
Civilization identities remain selectable; the first isolated scale preview uses
Sparta. These economy/conquest systems remain planned. See
[the miniature preview](MINIATURE_PREVIEW.md) and [the preserved build](BACKUPS.md).
The existing production game below still describes the prior playable build.

## Agreed experience

Eight players occupy eight protected settlement plots arranged in a circle
around a central battlefield. Each player selects a civilization and personally
fights alongside NPC troops, commanding their movement and formations.

Players expand their settlements and upgrade buildings, personal weapons,
abilities, and NPC fighters. Battlefield objectives award settlement resources.
Settlements are protected from raids in the initial design.

Each player has independent saved progress for every civilization. Starting
another civilization preserves the previous civilization's settlement and
upgrades. One civilization is active at a time.

On entry, the player chooses a civilization before being routed to a battlefield
server. Each civilization can be occupied by at most one player in a server.
Matchmaking must reserve a civilization slot before transfer and handle failed
transfers and expired reservations. Saved settlement data must not be tied to
a particular physical plot or server.

## Working civilization references

These are chosen reference windows for art and equipment, not complete dates
for the existence of each civilization. Historical technology does not determine
which faction wins; strengths, costs, formations, and counters need playtesting.

| Civilization | Reference window |
| --- | --- |
| Sparta | Classical period, approximately 500–400 BCE |
| Seneca, within the Haudenosaunee Confederacy | Approximately 1600–1680 CE |
| Britain | Georgian redcoats, approximately 1750–1815 CE |
| Mongol Empire | Early imperial period, approximately 1206–1260 CE |
| Viking-age Scandinavians | Approximately 900–1050 CE |
| Achaemenid Persia | Approximately 550–450 BCE |
| Sengoku Japan | Late Sengoku/early Momoyama, approximately 1550–1600 CE |
| Mauryan Empire | Approximately 320–250 BCE |
| Spanish Empire | Approximately 1500–1600 CE |
| Ancient Egypt | New Kingdom reference, approximately 1300–1200 BCE |
| Imperial Rome | Approximately 100–180 CE |
| Ottoman Empire | Süleyman's reign, 1520–1566 CE |
| Ming China | Approximately 1400–1600 CE |

The roster can contain more than eight choices; only eight can be active in
one full server. Britain uses redcoats and firearms. More troop types, additional formations, formation
bonuses and ability effects remain to be designed; current economy and combat
values are prototype tuning.

Historical references: [Ganondagan](https://www.ganondagan.org/bark-longhouse),
[Japan](https://www.metmuseum.org/essays/momoyama-period-1573-1615),
[South Asia](https://www.metmuseum.org/toah/ht/04/ssa.html), and
[British equipment](https://collection.nam.ac.uk/detail.php?acc=1950-11-33-31).

## Suggested prototype order

1. Verify Rojo connectivity and a placeholder eight-plot map in Studio.
2. Select Sparta or Britain and claim an available plot within one test server.
3. Buy one settlement upgrade and preserve separate progress for both civilizations.
4. Add one troop type with follow, hold, and a basic line formation.
5. Add player combat and one battlefield objective.
6. Add the entry lobby, civilization-aware cross-server routing, and reservation recovery.
7. Expand the art, troop roster, formations, and civilization choices through playtests.

This order is a proposed implementation sequence, not completed work. Matchmaking
must still be implemented before the intended public joining flow is available.

On October 14, the user chose to test the clicker/upgrade loop before adding
saving. The prototype now covers the full roster, physical tycoon pads, and
separate settlement/weapon/armor progression with equipped themed gear.
The user then prioritized the first automatic melee warrior: settlement stage 2
unlocks a barracks with one troop, replaced 15 seconds after death. Owner weapon
and armor upgrades apply to current and replacement troops. See [army details](ARMY.md).
Per-civilization persistence now saves coins and settlement, weapon, armor and
barracks levels. Selection waits for a successful profile load; a failed load
cannot replace earlier progress with a fresh profile. The HUD lets players
switch to an available civilization on the same plot and later restore the old
one. See [saved profiles](PROFILES.md) and [economy details](ECONOMY.md).

The army progression milestone softened gear scaling, added a 10-coin final-hit
reward, player melee and settlement-unlocked floor pads, and expanded
barracks through three faster-respawn upgrades to one melee plus one ranged troop.
See [army details](ARMY.md) and the active OpenSpec implementation checklist.

The proposed sequence above records the original plan. Current saving and army
features have overtaken some of its steps; additional formations, battlefield objectives and
civilization-aware cross-server routing still need implementation. Storage and
multiplayer verification are recorded separately in [playtest notes](PLAYTEST.md).

### Expanded world and fifty-level growth

The current world spans 1,600 × 1,600 studs, with eight protected plots spaced
around a 500-stud-diameter battlefield. Grassland, forest, desert, snowy highlands
and wetlands provide different scenery, with waterways and dry crossings.

Settlement progression now has 50 levels. The starter footprint remains 60
studs wide; each upgrade adds four studs and lasting details, reaching 256 studs.
Districts, ceremonial landmarks and larger halls express each civilization's
architecture. Weapon and armor progression also has 50 small linear steps:
melee damage ranges from 10 to 18 and standard maximum health from 100 to 140.
Barracks has six levels and two original slots. Army Camp I adds a
separate third slot with a saved choice of melee or ranged. Existing saved coins and
numeric levels are preserved under the new visuals and combat curve. See
[world and settlement growth](WORLD.md) for the layout and milestones, and
[economy details](ECONOMY.md) for current tuning.

Every upgrade track is capped by the settlement level: a level-two settlement
supports weapon, armor and barracks upgrades only through level two. Higher
settlement stages reveal early tier pads; stable weapon and armor pads offer
later levels. Civilization and owner names
belong on themed main-building facades, rather than a freestanding board that
blocks the settlement. Five user-provided character models supply the Spartan,
British, Japanese, Seneca and Mauryan melee troop visuals.

The first building progression milestone introduces Training Yard I at 5,
Farm I and Worker Camp I at 7, and Army Camp I at 10. Entering level 10 requires
the first training/farm/worker buildings and Barracks IV. Purchases complete
immediately. Available upgrades have floor pads beside their buildings; locked
ones stay hidden. Connected farming produces a saved coin reserve only while
playing that civilization, with tending workers in fields outside the future
settlement footprint. Training enables advance, hold and regroup orders.

The next economy slice adds Farm II and Worker Camp II at 12, independent
weapon/armor price workshops at 13 and Storehouse I at 16. Farming yields the
farm plus worker tier every five active seconds, reaching four coins; storage
increases the saved reserve from 60 to 180. Each workshop discounts only its
gear track by 5%, rounded upward, without changing combat stats. Barracks V at
8 and VI at 14 shorten future waits to 13 and 12.5 seconds, preserving existing
slots and pending timers. All fourteen progression/economy fields save per
civilization without changing the profile schema or keys.

The intended pace remains multiple 30–45 minute sessions with meaningful
purchases along the way. Later farm tiers at 20/30/42, Storehouse II and beyond,
checkpoint 20, more army slots, infirmaries, formations, abilities and specialist
buildings remain planned.
Current tuning has not yet established a measured level-50 completion time.

Spartan Shieldwall and Roman Shield Guard share the formation system: every
civilization can unlock Army Camp II and the War Council, while Sparta and Rome
buy two-hit shields and their own five-troop formation. The council map selects
the faction formation; March Formation musters three melee, one ranged and one
medic from camp, assembles at the road and
advances together at six studs/second. Center arrival or a frontline casualty
restores ordinary Advance; explicit Hold stays stationary. See
[army controls](ARMY.md) and [verified boundaries](PLAYTEST.md).

Persian Archer Screen extends the shared system with a straight spear/shield
line, an archer and a medic. It deploys for clear bow fire and retains a bounded
defensive position rather than releasing at center. Purchased shield training
also adds a rack near camp: recalled melee with spent shields physically
replenish before returning to training. See [army details](ARMY.md).

The recruitment consolidation moves combat capacity purchases to the Barracks,
retaining settlement 2/4/10/18 progression and a separate Hospital medic. An
owner-only recruitment screen sets future melee/ranged counts and zero/one medic
within unlocked capacity. Living troops and pending respawn deadlines are
preserved. The relocated Barracks, Training Yard, shield rack and War Council
form one military area; the standalone Army Camp building is removed. Fresh
shield-trained melee physically collect shields before following their order.
Persian Archer Screen now closes to 30 studs and slows to half pace after a clear
bow opportunity; see [army details](ARMY.md).
