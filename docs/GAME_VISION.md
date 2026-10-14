# Civilization Battlefield: game direction

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
one full server. Britain uses redcoats and firearms. Specific unit lists,
formation bonuses, ability effects, and economy values remain to be designed.

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
