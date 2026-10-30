# Miniature Economy Implementation

Latest revision: [Simple Shop and Automatic Troops](Simple%20Shop%20and%20Automatic%20Troops.md)
records the current research-free shop, automatic building-owned groups under ten
and expanded map. Older research/inspection/roster milestones below are history.


Updated 2026-10-29. This records the current isolated, fake-store gameplay
sandbox. Production progression, ProfileData V1 and the clean scale preview are
preserved. See [[Miniature Inventory and Shared Shops]] for interaction decisions,
[[Miniature Civilization Redesign]] for the design, and
[[2026-10-29-miniature-implementation|Miniature implementation log]] for evidence.

## Current settlement and workforce

All thirteen prototype civilization kits are delivered, with nine building roles
and three inert military/support role candidates per kit. Their historical forms
and interpretation limits are recorded in
[[Miniature Civilization Evidence Sheets]]. Economy rules are shared; inventories,
stock, research and progress remain private to each player and civilization.

An ordinary selected civilization starts with **200 Coins**, a civic site, a
house and a farm. Each placed house supplies **four automatic civilians**, capped
at **eight**. The starter therefore has four civilians: two farming and two idle.
Civilians cost nothing. Existing legal assignments stay stable; available
civilians fill free production jobs in building order. Each producer supports two
workers. Additional housing adds civilians, and reclaiming housing reduces the
population to the remaining capacity. Removed civilians' preset references are
pruned; remaining valid jobs stay intact.

Paid hiring, manual assignment, Move and Unpack remain internal legacy handlers
for focused regression coverage. They are not exposed Runtime actions or current
UI controls. There are no manual assignment/preset controls in the current UI.

## Goods and production

Harvested crops enter carried goods inventory, not the wallet. Food, Timber,
Material/Clay and Crafted Goods/Pottery sell for **2, 4, 6 and 15 Coins per unit**.
The wallet cap is one billion Coins. Inventory contains goods and separate
building items; Sell All sells goods only.

Each producer holds **60 output** locally. Collected goods share **200 capacity**,
or **400** while a purchased Storehouse is placed. Walk to a producer and press
**E** to collect all goods that fit, retaining any remainder in its local buffer.
The underlying exact-amount collection ledger remains tested internally.

`Config.productionSpeed = 10` explicitly accelerates this Studio-only sandbox.
Catalog base intervals remain ten seconds for Farm/Timber and fifteen for
Clay/Pottery; actual test intervals are **1 and 1.5 seconds**. Organized Work
changes raw intervals to **0.9 seconds for Farm/Timber and 1.35 for Clay**;
Pottery stays at **1.5 seconds**. Each farmer yields two Food per interval; each
Timber/Clay worker yields one raw good. Each potter consumes one collected Clay
and yields one Pottery per interval. Clay is a manufacturing ingredient, **not a
purchase currency**.

Only complete worker batches run, with at most six overdue batches processed per
producer. Full, inactive, unassigned and insufficient-input periods discard
blocked time. Offline time never produces goods. Old workforce, rate and capacity
settle before structural changes; new assignments start fresh clocks at commit.
Settlement switches pause inactive production and restore automatic population
and jobs on return. This ten-times speed is test tuning, not final game balance.

## Shops, building items and reclaim

Exactly three top buttons provide server-chosen travel: **Buy / Civilization /
Sell**. Buy and Sell lead to two shared stalls serving every civilization;
Civilization returns to the owned plot. Travel has no price and accepts no client
coordinates. Purchases require proximity to the shared buy stall; manual sales
require proximity to the shared sell stall. Life, write authority, current claim,
revision and replay checks still apply.

Every building, hall improvement and research purchase costs **Coins only**.
Buying consumes one personal merchant stock and pays once for a building item.
Selecting that item from inventory/hotbar starts placement; confirmed placement
consumes it without another charge. Cancel preserves the item. Held plans have
**twelve slots**, separate from goods; placed buildings have **twelve slots**.
Placement validates the owned plot, two-stud grid, cardinal rotation, overlaps and
reserved lanes.

The personal merchant replaces stock every **180 seconds**: two Farm and House
items each, and one of each eligible advanced item. Research unlocks eligibility
for the next merchant cycle. Missed cycles do not accumulate stock, and owned or
held unique buildings prevent duplicate stock. The shared physical stall does
not make another player's stock or inventory available.

The **Destroy Hammer** reclaims an eligible owned building into exactly one
building item, without a Coin refund or rebuilding fee. All stored output first
transfers to carried inventory; if the complete buffer will not fit, the entire
request is refused without changing output, plans, workers or wallet. Successful
reclaim releases its jobs and reconciles civilians automatically. The starter
farm can be reclaimed and rebuilt. The civic site and last house stay protected;
plan capacity, Storehouse capacity and military-presentation dependencies also
block unsafe reclaim.

The sell stall's **Sell all goods** button atomically prices every carried good,
clears those goods and credits their combined Coin value. An empty inventory or
wallet overflow is refused without mutation. Replaying the same accepted intent
returns its receipt without another sale or duplicated value.

## Research and optional services

Improving the council costs **160 Coins**. One research project runs at a time;
each branch costs **100 / 180 / 240 Coins** and takes **30 / 60 / 90 active seconds**.
Research and merchant clocks retain their ordinary durations despite accelerated
production. Payments happen once at project start. Remaining active time is
saved within the fake server; inactivity/offline time does not finish projects.
Research unlocks eligibility rather than granting free plans or buildings.

| Branch | First node | Second node | Third node |
| --- | --- | --- | --- |
| Economy | Organized Work: raw intervals ×0.9 | Craft Traditions: workshop eligibility | Storekeeping: Storehouse eligibility |
| Army | Muster: training and two fighter presentations | Drill Yard: four fighter presentations | Supply Organization: healer and one support presentation |
| Civic | Settlement Records: prerequisite for Porter Service | Porter Service: optional collection | Trade Steward: optional sales above reserves |

Old preset data and internal handlers remain compatible; Settlement Records does
not currently expose manual preset controls. Porter and Trade settings default
off. Automation runs only in the active, authoritative settlement and uses the
same conservation checks as manual collection/sales. Automatic sales protect the
greater of a configured reserve and the next complete input batch for each
staffed workshop. Explicit manual Sell All sells all carried goods.

Roster selections require completed research and the corresponding placed
training/healer building. These figures are independent of the workforce and
remain passive: this sandbox implements **no combat or healing**.

## Current verification

`npm run check:miniature` passes **65 deterministic Luau cases** with fake storage.
They cover automatic population and stable jobs, house population shrink,
settle-before-change clocks, starter-farm reclaim/rebuild, full-buffer transfer,
capacity/roster protection, coin-only purchases, complete recipe batches,
accelerated active intervals, Sell All pricing/overflow, stale requests, replay,
private stock, research prerequisites and session authority. Pinned StyLua and
Selene pass for the changed backend modules and specs.

The current native inventory flow passed E collection of **60 Food**, Sell All
for **120 Coins** (200→320), and an **80-Coin house item** (320→240). Placement
consumed the item without another charge and expanded automatic population
**4→8**. Hammer reclaim transferred **48 Food**, including production settled at
the transaction, and returned one farm item. Rebuilding consumed that item with
no fee and restored **eight civilians, two assigned**. The fixture used native
input and server travel without extra funding, local relocation or local render
injection. See the [current passing receipts](../assets/miniature-inventory-green-2026-10-29.json).

The earlier hammer/prompt conflict and its retained
[failure record](../assets/miniature-inventory-red-2026-10-29.json) preceded that
passing flow. The [final run](../assets/miniature-inventory-final-2026-10-29.json)
also passed four layouts, civilization restoration and real death/respawn with
16.27 horizontal studs of walking and preserved inventory. The user confirmed
physical movement after the default-controller readiness fix. Physical number1,
phone/controller input, published multiplayer and live storage remain separate checks. Fake-only
progress resets when its Play server stops.

## Historical native receipts — previous interaction contract

These October 29 milestones document the earlier manual-management build. Their
slower timers, hiring/assignment/preset controls and material purchase costs do
not describe the current interaction or economy rules.

The starter fixture collected ten of twelve Food, leaving two; sold ten for
20 Coins (200→220); bought an 80-Coin house plan (220→140); and checked cancellation
and one-time placement consumption. Four bounded UI layouts passed. See the
[[2026-10-29-miniature-implementation|milestone log]] for this dated evidence.

The funded advanced fixture passed Move/Unpack, 25-Coin hiring, manual Clay
reassignment/collection, council improvement, real 30-/60-second research,
next-cycle workshop purchase and Clay→Pottery→15-Coin sale. Funding was explicit
fixture setup. See the [advanced receipts](../assets/miniature-advanced-native-2026-10-29.json).

The pre-unlocked services fixture passed displayed capacity 400, 9.65-second
Timber, preserved workers with passive 3/1/1 figures, presets, reserve-aware
Porter/Trade automation and manual controls. Its nine completed research nodes
were seeded, not natively researched. See the
[services receipts](../assets/miniature-services-native-2026-10-29.json) and
[[Miniature Services Verification]] for the separate clean **201/400 goods**
capacity transfer and its declared seed. These records establish no combat,
healing, live saves or published-client acceptance.
