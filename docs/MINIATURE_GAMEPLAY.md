# Miniature settlement gameplay sandbox

This is a separate Studio-only development project. The clean scale sample
remains `miniature.project.json`; production remains `default.project.json`.
The sandbox injects FakeProfileStore and never opens player DataStores. Its
ordinary starter has **200 Coins**, a council, house, farm and four civilians
(two farm jobs and two initially idle). Funded verification modes are separate
test projects. The compact shop and automatic troop revision passed native
verification; see the [current interaction note](notes/Simple%20Shop%20and%20Automatic%20Troops.md).

All thirteen civilizations now have distinct prototype building kits and
miniature army figures: Sparta, Britain, Seneca, Mongol Empire, Vikings, Persia, Sengoku
Japan, Mauryan India, Spanish Empire, Ancient Egypt, Imperial Rome, Ottoman Empire
and Ming China. Each kit supplies ten original building roles and three
military/support role candidates. A shared factory now adds an eleventh,
civilization-specific mounted-animal facility; its verification scope is recorded
below. Architecture follows each civilization's declared period; these
remain gameplay interpretations with source gaps recorded in the
[evidence sheets](notes/Miniature%20Civilization%20Evidence%20Sheets.md).

## Launch the ordinary sandbox

From Windows PowerShell at the repository root:

```powershell
& "C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" build miniature-playtest.project.json -o build\miniature-playtest.rbxlx
```

Open `build/miniature-playtest.rbxlx` in its own Studio window and press Play.
Rebuilt `.rbxlx` files already contain the code; do not click Rojo Sync for this
workflow. Sync is only needed during an explicitly served live connection using
`miniature-playtest.project.json`. The latest ordinary review copy is
`build/miniature-mount-refinements-playtest.rbxlx`, with80×64starting plots, decorated
capturable outposts, original troop rigs with smooth client poses, near-peer
neutral defenders, attached face decals and32stud/second commander walking. Already running
older sessions keep their previous dimensions until the rebuilt place is opened.
The separate `build/miniature-mount-refinements-funded-review.rbxlx` gives every
one of the thirteen civilizations 20,000 test Coins so its mount facility can be
tried immediately. This player review copy runs gameplay without diagnostic
scenes or a required Spartan test sequence. The ordinary build starts at 200 Coins.
Fake progress survives civilization switches and rejoining that same Play server,
then resets when the server stops. It cannot replace production or preview
progress. The sandbox uses port 34874 if explicitly served; never connect it to
the production or scale-preview window.

## Play the current slice

Choose a civilization. The three top buttons are **Buy / Civilization / Sell**.
Buy travels to the shared building stall and opens the compact shop; Sell travels
to the shared goods stall and opens Sell All; Civilization returns to your owned
plot and closes popups. The small HUD's Change civilization button opens the
civilization chooser. No Inspect, research, upgrade-hall or training-roster pages
are needed.

The shop has exactly **Homes / Production / Military** tabs and scrolling rows:
structure image, Coin price, brief function and stock. Every building is available
without research. Military stock starts/restocks at two of each type; farm/house
stock is two and other advanced stock one, on180-second private owner/civilization
cycles. Prices use Coins only. Goods are inventory items or recipe inputs.

**B** opens inventory. Select a building item or hotbar slot to place it; **R**
rotates and Confirm commits. Cancel keeps the item. Select the Destroy Hammer to
return an eligible clicked building to inventory without another purchase fee.
Stored output transfers first; full inventory/dependency checks refuse rather
than discard contents. Civic and last house remain protected. Toggle the hammer
off for ordinary producer E collection. Clicking normally opens no inspector.

Houses automatically provide four civilians each up to eight. Available civilians
fill producer jobs while existing valid jobs remain. No paid hiring or assignment
controls. **E** at a producer collects everything that fits; Sell All converts
all carried goods into Coins. Farm/Timber batches take one active second and
Clay/Pottery1.5seconds at the explicit10×testing speed. No offline/full-buffer/
inactive time accrues. Pottery consumes clay as an ingredient, never currency.
Research projects, bonuses and automated research services are paused.

Each melee building supplies **two melee**, ranged building **two ranged** and
medic building **one medic**. The fixed army limit is **ten including medics**,
separate from civilians. Buildings supply whole groups but do not raise capacity;
extra groups wait and fill room when it becomes available. Reclaiming a military
building removes its own figures and may allow a waiting group to spawn. These
now fight automatically using the original baseline encounters, targeting,
spacing, ranged retreat and medical services. The original outfits, rigs and
joint animations are quarter scale with grounded feet. Ordinary owned foot troops move at 6
studs per second; neutral health, damage and speed are 95% of their matching
player role, including 5.7-stud foot movement. Both ranged roles reach 10 studs
and medic healing reaches 7.
Progression-gated formations/shields/skills remain for later progression.

The world is1200×1200studs, with eight centers on a400-stud radius. Starting
build areas are now80×64, four times the former40×32area, with160×128future
expansion space reserved around each. The larger starting area is free; expansion
purchases will come later. Existing buildings retain their local positions.
There are thirteen selectable civilizations, ten original building roles per
kit and one additional mount facility per civilization. Placed buildings and held
building items have no fixed aggregate count cap; legal plot space still applies.
Limits remain 200 goods (400 with Storehouse),
60 output per producer, eight civilians and ten weighted army slots.
Walk/Overview and independent minimization remain available.

Each plot has a neutral outpost110studs inward toward the center, defended by two
melee and one ranged troop. Building-owned armies automatically attack their own
line's outpost, then guard it. Defeat defenders and occupy it for20clear seconds;
returning defenders pause progress, rivals contest it and losing all attackers
resets it. Capture flies your civilization's flag. Walk to any outpost center and
press E to retarget your entire army, including replacements. Homes, commanders
and civilians cannot be conquered or damaged. Deeper line objectives remain
future map content. See [combat controls and evidence](notes/Miniature%20Combat%20and%20Outposts.md).

See [Simple Shop and Automatic Troops](notes/Simple%20Shop%20and%20Automatic%20Troops.md)
for the current screenshot, source/evidence links and exact verification scope.

## Mounted troop slice

Each civilization now has a **5,000-Coin mount facility** in the existing Military
tab, with its own structure image, name and inventory item. Placement consumes one
held plan and supplies one original rider on its approved fantasy animal. A
mounted troop uses **two of the fixed ten army slots**; foot troops and medics use
one each. The HUD's Army total is weighted usage, and its Mounted count is the
number of allocated mounted troops. A mount waits if only one slot remains.
Facilities occupy **12 × 10 studs** and retain normal placement/reclaim guards.
Elephants and camels now move at **5.5 studs/sec**, slightly below ordinary troops
at **6**; other mounts remain at **9**. Elk and bear proportions, lion seating,
bull feet, crocodile gait and wolf/rhino facial details follow the latest
[refinement note](notes/Mount%20Refinements%20and%20Ragdoll%20Deaths.md), which also
tracks physical ragdoll verification and the removed structure-count ceilings.

Confirmed troop deaths now produce local physical ragdolls for riders and animals
as well as foot troops. Bodies fade and expire after six seconds; exact-life
server notices prevent corpses from hammer reclaim or civilization switching.
The native tests verify default query exclusion and unchanged commander walking,
plus independent limits of twelve corpses, 1,200 parts and eight shared support
proxies. Building-owned respawn and capture rules remain authoritative on the server.

Current checkpoints pass **142 logic cases**, all **11 sanitized animal templates
with 523 original parts**, **13 native facility factories**, and native mounted
geometry covering **13 original riders, 918 parts, 133 anatomy joints, 156 server
poses and 234 client poses**. The basic real-UI Spartan run buys and places its
lion facility, spends **5,000 → 0 Coins**, and shows **one mounted troop at 2/10**.
The extended native run passes all seventeen normal-input actions, the one-free-
slot wait, hammer backfill and whole-army E capture. It retains 9,050 of its 20,000
test Coins and finishes with seven figures using nine slots. Fresh full-catalog
legacy kit gates and original foot-pose checks also pass. See
[Mounted Army Implementation](notes/Mounted%20Army%20Implementation.md) for the
roster, screenshots, measured evidence and explicit limits. The mounted review
copies named above contain these changes.

## Generate native verification places

Generate the separate native test place from WSL:

```bash
npm run build:miniature-game-tests
npm run build:miniature-game-tests -- --shop
npm run build:miniature-game-tests -- --mounts
npm run build:miniature-game-tests -- --advanced
npm run build:miniature-game-tests -- --services
```

For funded player review without diagnostic autoruns, use
`npm run build:miniature-game-tests -- --mounts --review` and build
`.cache/miniature-game-mounted-review.project.json`. It needs no template
fingerprint setup. The native diagnostic projects below retain that setup.

Choose one generated project and build it with the installed Rojo command:

| Mode | Generated project | Declared fake setup |
| --- | --- | --- |
| Ordinary | `.cache/miniature-game-test.project.json` | 200-Coin starter |
| Shop | `.cache/miniature-game-shop-test.project.json` | 5,000 Coins only; zero goods/plans, no research, ordinary starter positions |
| Mounts | `.cache/miniature-game-mounted-test.project.json` | 20,000 Coins per civilization; zero goods/plans, no research or army injection |
| Advanced | `.cache/miniature-game-advanced-test.project.json` | 5,000 Coins, 80 Timber, 20 Clay; starter workers/buildings and locked hall/research |
| Services | `.cache/miniature-game-services-test.project.json` | 5,000 Coins, 80 Timber, 20 Clay; compact starter, improved hall and all nine research nodes already completed |

For example, build the ordinary project to `build/miniature-game-test.rbxlx`.
Use a separate output filename for funded modes. The generator replaces the
ordinary Bootstrap; each generated place must contain exactly one
`ServerScriptService.Sandbox.Bootstrap`, injecting the fake store, and no
production `Game` folder. Never run both bootstraps together. In Play, read
`ReplicatedStorage.MiniatureIsolationResult`; `passed` proves the isolated
bootstrap started without production services or the decorative preview.
Keep the user's playtest and at most one owned verification run open together.
Before pressing Play in a generated test place, record the original template
fingerprint in **Edit** so native immutability checks have their required baseline:

```luau
game.ReplicatedStorage:SetAttribute("OriginalSandboxTemplates", require(game.ServerStorage.TemplateFingerprint)())
```

In a fresh **shop** verification Client, run:

```luau
require(game.ReplicatedStorage.NativeOutpostFlow)({ funded = true })
```

This current fixture uses native UI for research-free buying, placement of4/4/1
troop buildings, actual commander walking, automatic battle/capture, neutral life
replacements, a measured paused/resumed bar, flag ownership and E retargeting.
Read Client `MiniatureOutpostFlowProgress` and JSON `MiniatureOutpostFlowResult`.
The5000-Coin seed is explicit testing setup; the ordinary build starts at200.

For the frame/lifecycle check, keep the owned test window active and use the
generated native LocalScript runner. In the Client command context, set
`game.ReplicatedStorage:SetAttribute("RunMiniatureArmySmoothing", true)` before
the UI flow buys its army, or before a normal E order sends a living army marching.
Read `MiniatureArmySmoothingRunnerFinished` and `MiniatureArmySmoothingResult`.
The runner is dormant until requested and exists only in generated test projects.
Do not call the frame fixture directly from the tool VM: that observer sampled
at15Hz while the native LocalScript passed at60FPS with unchanged thresholds.
Server `NativeOutpostScenery` verifies all eight integrated compounds.

See [smooth armies and frontier outposts](notes/Smooth%20Armies%20and%20Frontier%20Outposts.md)
for the latest native evidence, balance numbers and verification limits.

In the verification Server, run the separate adapter/rival fixture:

```luau
require(game.ServerStorage.NativeOutpostScene)()
require(game.ServerStorage.NativeOriginalArmyScene)()
```

Its `MiniatureOutpostSceneResult` covers8outposts, source immutability, actor life
rendering, effects and simulated rival recapture. It uses temporary models and a
fake clock, not actual second-player input. Run it before the Client flow so its
temporary prompts cannot overlap the player's native E observation.
The original-army fixture reports `MiniatureOriginalArmySceneResult` and checks
39faction roles plus2neutral roles, five custom skins, clothing/equipment/grips,
518posed-foot samples and actual support raycasts excluding avatar obstacles.

For mounted geometry, run the separate Server fixtures:

```luau
require(game.ServerStorage.NativeMountStructures)()
require(game.ServerStorage.NativeMountedScene)()
```

A fresh **shop** verification seed supports the basic Client purchase flow:

```luau
require(game.ReplicatedStorage.NativeMountedFlow)()
```

The separate **mounts** seed prepares the extended capacity flow:

```luau
require(game.ReplicatedStorage.NativeMountedFlow)({ extended = true })
```

Adding `capture = true` requests actual walking, E retargeting and capture after
backfill. The recorded extended run passes with capture enabled. After it, run
`require(game.ReplicatedStorage.NativeMountedRemoval)()` to verify mount-plan
return, weighted capacity release and source/local-clone cleanup through normal
travel, walking and hammer input.
Read `MiniatureMountedFlowProgress` and `MiniatureMountedFlowResult`; a seeded
wallet or started fixture is not acceptance evidence.

Never require PlayerModule or invoke InputReadiness from the tool VM: that cache
can create a competing controller. Fixtures observe the actual Humanoid and use
native input. InputReadiness belongs only to the actual game LocalScript.

Earlier Inventory/SimpleShop/Management/Services/research native fixtures are historical
contracts. Their saved evidence does not describe the current compact interface,
research-disabled settings or per-building troop allocation. Advanced/services
modes remain diagnostic setup only; do not claim native completion from a seed.

Starting a fixture or building its place does not establish a pass. Read the
result attributes and recorded receipts; after source edits use a fresh Play or
fresh ModuleScript because Roblox caches `require` results.

## Fake-only state and claims

The new `Sessions` service receives a fake store, clock and token source. Its
`miniature-development:<UserId>` keys exist only inside that injected fake. It
does not import ProfileData/ProfileService or access Roblox storage. Version-one
production records are untouched. `npm run check:miniature` executes the actual
new logic with the existing fake store and pure ClaimRegistry implementation.

The miniature record has its own schema version, per-civilization inventories,
plans, local placements, worker assignments, research, personal merchant stock
and convenience settings. Counts, resource limits, footprint overlap, reserved
lanes and cross-field prerequisites validate before activation. Snapshots are
copies. A malformed existing record or failed load never becomes a new default.

Eight independent plots and thirteen exclusive faction identities are managed
by a new registry instance. Switching retains the plot and each civilization's
state. A 60-second fake-store lease guards writing; saves renew only the acquired
token. Expiry/takeover blocks old writers. Concurrent close/save calls serialize,
and a failed final save remains closed and available for a bounded retry.
Production partial intervals and actor state are not part of the saved domain.

## Request boundary

`Requests` consumes a server-derived sender and action plus an intent containing
`requestId`, `sessionId`, `claimEpoch`, `revision` and bounded `args`. It rejects
unknown envelope fields, nonfinite/oversized values and excessive nesting. A
per-player burst of eight requests refills at four per second; receipts retain
at most 32 accepted intents and are removed on departure.

Every intent rechecks current write authority, life and server-derived distance.
Session/claim changes invalidate drafts; stale revisions cannot spend twice.
Handlers mutate a copied state, whose invariants validate before committing it.
The server chooses prices and ownership. Repeated accepted intents receive their
receipt without another mutation. Public snapshots copy the owner's current
state; they never expose another player's balances or storage record.

## Verification and scope limits

The [original-army follow-up](notes/Original%20Miniature%20Army.md) passes108miniature
cases, including10cases executing actual original planners/services with Lune
Roblox vector/CFrame maths;5Node cases,351syntax compilations,244existing logic
cases and30OpenSpec items also pass. Native source-rig/ground tests and actual
original-model/tactics UI capture/E override pass. One original Spartan torso
decal has a platform asset-permission warning; the source is preserved. See the
linked note for exact evidence, native screenshot, performance sample and limits.

The current combat change passes98miniature logic cases,5Node cases,345syntax
compilations,244existing logic cases and29OpenSpec items, plus Selene/StyLua.
Native checks pass actual UI army purchases/placement, march, combat, respawn
waves, paused/resumed capture, the flag and E override. A separate native adapter
fixture verifies simulated rival recapture and source immutability. The actual
Studio viewport confirms health/capture billboards and the E prompt; MCP images
omit those world interfaces. Exact funding and remaining limits are recorded in
the [combat note](notes/Miniature%20Combat%20and%20Outposts.md).

October 29, 2026, current simple-shop revision: development gates passed28
OpenSpec items, five Node tooling checks,336 Luau syntax compilations,244 existing
logic cases and73 miniature cases, with clean changed-file Selene/StyLua checks.
Native checks passed the compact shop, E collection, Sell All, purchasing and
placing melee/ranged/medic buildings, hammer reclamation/replacement, four bounded
layouts, civilization restoration and movement after an actual respawn. Separate
native scene checks passed all thirteen ranged factories, the fixed ten-troop
allocation/backfill and the1200-stud map with separated expansion reservations.
The shop verification fixture explicitly started with5000 Coins and zero goods;
the ordinary sandbox still starts with200 Coins. See the
[current interaction note](notes/Simple%20Shop%20and%20Automatic%20Troops.md) for
the screenshot, exact evidence and limits. Earlier research/service and capacity
fixtures remain historical evidence; research is disabled in the current build.
Simulated multi-owner checks establish isolation within their fixture; they do
not establish published multi-client behavior. UI viewport checks do not establish
physical phone or controller acceptance. The passing capacity run used one
Bootstrap and reported no first-party script errors.

Physical-device play, published multiplayer and live-storage verification remain
separate work. The ordinary bootstrap deliberately rejects non-Studio servers;
publishing this test place does not enable a live game. No published multiplayer,
research completion from pre-unlocked services setup or production release is
claimed. Historical notes distinguish sourced forms from interpretive role props.

See the [implementation log](notes/2026-10-29-miniature-implementation.md) for
exact evidence and the [redesign tasks](../openspec/changes/miniature-civilization-redesign/tasks.md)
for implementation status. Rojo builds and isolation checks alone do not
demonstrate gameplay behavior.
