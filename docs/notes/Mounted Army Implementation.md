# Mounted army implementation

The latest proportions, species speeds, removed structure-count ceilings and
ragdoll work are tracked in
[Mount Refinements and Ragdoll Deaths](Mount%20Refinements%20and%20Ragdoll%20Deaths.md).
The original foundation checkpoints below retain their dated evidence.

The user supplied animal models, authorized changes to their scale, animation and
decoration, and requested unique mount structures costing **5,000 Coins**, with
each mounted troop using **two army slots**. The approved fantasy identities are
in [Mounted Troop Concepts](Mounted%20Troop%20Concepts.md). Implementation is tracked
by [miniature-mounted-armies](../../openspec/changes/miniature-mounted-armies/proposal.md).

## Current implementation

One placed animal facility supplies one automatic mounted troop. The army cap
remains ten; melee troops, ranged troops and medics each use one slot. A mounted
group waits when fewer than two slots remain and backfills when capacity opens.
The HUD shows the mounted count separately from weighted army capacity. The
existing Military tab, building inventory, placement controls and Destroy Hammer
handle mount facilities; no research or roster page is added.

Mounted troops use the original melee targeting and contact cadence, server life
and damage authority, outpost capture and E orders, medic healing and replacements
owned by their building. Their shared prototype budget is **300 HP, 48 damage per
validated melee contact**, with **9 studs per second** for most mounts and
**5.5** for elephants/camels after the refinement. Player riding, charge skills and
flight are outside this slice. Animal facilities use a **12 × 10-stud footprint**;
only their marked footing is queryable for grounding. Scenery remains anchored,
noncolliding and nontouching.

Each civilization has its own facility and decorated original R6 rider. The
supplied animal geometry is adapted on fresh clones. Persia's leopard derives
from the tiger; British and Mongol horses share their supplied source geometry
with different scale, riders and decoration. Fantasy animals do not change the
existing architecture reference windows or establish historical mounted traditions.

| Civilization | Animal | Structure |
| --- | --- | --- |
| Sparta | [Lion](../assets/miniature-mounted-gallery-2026-10-29/sparta.jpg) | Lion Guard Den |
| Britain | [Horse](../assets/miniature-mounted-gallery-2026-10-29/britain.jpg) | Royal Cavalry Stables |
| Seneca | [Elk](../assets/miniature-mounted-gallery-2026-10-29/seneca.jpg) | Antler Lodge |
| Mongols | [Horse](../assets/miniature-mounted-gallery-2026-10-29/mongols.jpg) | Steppe Rider Corral |
| Vikings | [Bear](../assets/miniature-mounted-gallery-2026-10-29/vikings.jpg) | Berserker Bear Hall |
| Persia | [Leopard](../assets/miniature-mounted-gallery-2026-10-29/persia.jpg) | Royal Leopard Garden |
| Japan | [Tiger](../assets/miniature-mounted-gallery-2026-10-29/japan.jpg) | Tiger Banner Dojo |
| Maurya | [Elephant](../assets/miniature-mounted-gallery-2026-10-29/maurya-fixed.jpg) | Mahout Elephant Yard |
| Spain | [Bull](../assets/miniature-mounted-gallery-2026-10-29/spain.jpg) | Toro War Pens |
| Egypt | [Crocodile](../assets/miniature-mounted-gallery-2026-10-29/egypt.jpg) | Nile War Pool |
| Rome | [Wolf](../assets/miniature-mounted-gallery-2026-10-29/rome.jpg) | Capitoline Wolf Den |
| Ottomans | [Camel](../assets/miniature-mounted-gallery-2026-10-29/ottomans.jpg) | Sultan's Camel Court |
| Ming | [Rhino](../assets/miniature-mounted-gallery-2026-10-29/ming.jpg) | Ironhide Rhino Pavilion |

## Script and asset review

The [import audit](../assets/miniature-mount-import-audit-2026-10-29.json) covers
**11 models and 32 scripts**. Imported touch damage, riding controls, remotes,
physics, sound and replacement logic conflict with the game's authority, so
originals are backed up and gameplay exports remove their executable behavior.
The unmapped raw archive preserves **527 parts and all 32 scripts**; omitting four
seat parts leaves **523 original parts in 11 inert templates**. See
[mount model handling](../../assets/MOUNT_MODELS.md).

Runtime animation and decoration operate on clones. The source fingerprint's
signed-zero correction treats only complete `-0` CFrame text tokens as `0`; it
does not ignore real geometry changes. A
[read-only comparison](../assets/mount-fingerprint-signedzero-proof-2026-10-29.json)
checked all 523 template parts against their repository assets and found no Size
or CFrame differences above the stated tolerance.

## Verified checkpoints

The following checks passed for the current slice:

| Check | Proven result |
| --- | --- |
| Automated miniature logic | **142 cases**, including weighted capacity, one-free-slot waiting, reclaim backfill, payment, missing-only fake-state defaults, original combat/healing and mixed mounted capture. Four pose-protocol cases cover mounted speed and unchanged foot-troop packets. |
| Offline supplied assets | **11 sanitized templates and 523 parts**; the raw **527-part / 32-script** archive remains intact. |
| Native facility factory | **13 facilities** pass footprint, distinct geometry, support-marker and source-immutability checks. |
| Native mounted geometry | **13 original riders, 918 parts and 133 anatomy joints**; **156 server poses and 234 client poses** pass the mounted geometry fixture. |
| Native basic purchase and placement | Actual Military-shop purchase, inventory selection and placement of the Spartan lion facility spend **5,000 → 0 Coins**, consume one plan and allocate **one mounted troop at 2/10 army slots**. |
| Fresh original kit regression | All civilization scene checks and sandbox isolation pass with the new source fingerprint. Original foot troops retain **39 roles, 518 grounded poses and 518 client-solver poses** across thirteen civilizations. |
| Native paid mixed army | **17 first-attempt actions** use normal buttons, ground clicks, W walking and E. The declared 20,000-Coin fixture spends 10,950 and retains **9,050 Coins**. No state or actor-position injection is used. |
| Native weighted queue/backfill | Infantry uses seven slots; the first rider brings usage to nine. A second mount facility waits with one free slot. Hammer removal of one melee barracks returns its plan and backfills the rider. **Six unaffected living actors retain their identities**. The final army has two mounts, two melee, two ranged and one medic: **seven figures using nine slots**. |
| Native mounted removal | Normal travel, W walking and hammer reclaim return one mount plan without charging Coins. The facility, mounted source and local clone disappear; HUD usage falls **9 → 7**. The other rider retains its source life, client clone and 300 HP. See the [removal record](../assets/miniature-mounted-removal-native-2026-10-29.json). |
| Native combat and conquest | Both mounted lives attack, take damage and remain attached to their local visuals. Real E sends the mixed army to its outpost; it captures and raises Sparta's flag in **53.20 seconds**, including the commander approach. Neutral respawns pause progress under the existing twenty-clear-second rule. |

These are separate checkpoints. Pure simulated capture does not establish native
mounted combat, and one Spartan UI purchase does not establish thirteen separate
UI flows. The fixtures are
[MountStructures](../../tests/miniature-game/MountStructures.luau),
[MountedScene](../../tests/miniature-game/MountedScene.luau) and
[MountedFlow](../../tests/miniature-game/MountedFlow.luau). Their result attributes
are `MiniatureMountStructuresResult`, `MiniatureMountedSceneResult` and
`MiniatureMountedFlowResult`.

## Integrated evidence and launch

The [final native record](../assets/miniature-mounted-final-native-2026-10-29.json)
contains the actual UI receipts, weighted counts, captured flag, fresh kit gates
and unchanged source fingerprint. The
[thirteen-image gallery](../assets/miniature-mounted-gallery-2026-10-29/manifest.json)
records the separate controlled visual review, including the corrected Mauryan
howdah seat. Those gallery actors never enter combat or change a player's army.

A passive native LocalScript observed the two real mounted lives for 69.5 and
75.4 seconds. It recorded 11 and 16 attack cues, all five movement/contact phases,
more than 1,170 local movement frames between source packets per rider, and hidden
source heads/faces throughout. The sample averaged about 45 FPS while Studio
windows changed focus; it establishes local interpolation, not a device benchmark.

`npm run check:dev` passes: **32 specification items, clean changed-file Selene and
StyLua, six Node tests, 376 syntax compilations, 244 existing logic cases, 142
miniature cases and the eleven-template asset audit**.

Open `build/miniature-mount-refinements-playtest.rbxlx` for the ordinary **200-Coin**
start, or `build/miniature-mount-refinements-funded-review.rbxlx` for the explicit
**20,000-Coin start for each of the thirteen civilizations**. The testing grant
is seeded once per fresh fake profile, so spending and switching never refill it.
The updated review copy is also named `build/miniature-all-civs-funded-test.rbxlx`.
Its [native funding probe](../assets/miniature-all-civs-funding-2026-10-29.json)
verifies all thirteen 20,000-Coin states, independent player/civilization balances,
preserved spending, the production-key guard and unchanged 200-Coin ordinary
starters. It runs against an isolated fake store in Edit, without changing the
active playtest. Start a fresh Play in the updated copy to use these balances.
Both contain the latest mounted gameplay. The funded player review omits native
diagnostic autoruns and needs no template fingerprint setup. Separate native
test places retain those checks; see [the gameplay guide](../MINIATURE_GAMEPLAY.md).
Rebuilt files need Play, without Rojo Sync. `build/miniature-playtest.rbxlx` is
also refreshed from the ordinary build. The user's import workbench and existing
original-army Play remain separate.

Production, real storage, published multiplayer, physical phones/controllers and
adverse-network performance remain outside this prototype verification. Ordinary
starters still have **200 Coins**; funded test bootstraps never access production player data.
