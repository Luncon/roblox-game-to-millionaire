# Design

## Context

See proposal.md for motivation and scope. `miniature.project.json` currently
starts `prototypes/miniature/server/Bootstrap.server.luau`, which builds one
shared Spartan display scene from a small frozen config. World/Actors are visual
and do not own economic state. Its UI provides inspection and Walk/Overview.
The native Scene/Input/Templates fixtures assert three buildings, six actors,
quarter scale and absent production services.

The production game has authoritative economy/profile/claim code, appearance
helpers and thirteen broad architecture styles, but its fixed pads, fifty-level
tracks and twenty-scalar save schema do not represent owned placements or goods.
Its architecture also shares generic shape families (including Seneca/Viking
longhouses and Mauryan/Ottoman domes), which cannot satisfy the new kit contract.
Do not copy these simplifications into new art without role-specific redesign.

The CLI's older context still says players fight. The newer user decision and
GAME_VISION miniature direction control: commanders are unarmed and normal size.
The thirteen historical periods are retained; no roster migration is proposed.

## Goals / Non-Goals

**Goals:** add a separately launchable, fake-store miniature economy with bounded
work, conservative transactions, predictable restocks, visible research and
verifiable faction art. Deliver one working Spartan loop before multiplying art
across thirteen kits. Keep price/effect configuration reviewable and testable.

**Non-Goals:** modifying the current preview contract, reusing production bootstraps,
publishing, opening real stores, migration, functioning combat/healing, player
weapons or a general-purpose market/quest/alliance framework.

## Decisions

### 1. A new explicitly mapped sandbox project

Add `miniature-playtest.project.json` with gameplay modules under
`prototypes/miniature/game/{shared,server,client}`. Explicitly map only required
pure shared data and appearance helpers. Inject FakeProfileStore at the sandbox
entry point and reject non-Studio startup. The original miniature project and
its fixed scene fixtures stay intact. Do not map the whole production server or
client folders. New native fixtures get a separate generated test project.

Alternative: add a gameplay toggle to the existing preview/bootstrap. Rejected
because a mode mix-up can change the clean scale sample, duplicate display actors
or load production profile/combat services. A separate mapping is easy to audit.

The eight-plot claim loop uses a sandbox-owned registry and its own claim epochs.
Reuse pure claim algorithms only after tests; importing a production module must
not transitively start its systems. A fake load failure blocks claiming. Release
or switch invalidates the old context before new actors, clocks or UI activate.

### 2. Catalog roles, independent faction renderers

Shared data contains stable building-kind IDs, two-stud grid footprints,
permitted orientations, worker/output slots, prices and research requirements.
Local plot coordinates avoid persisting server-specific world positions. Keep
four-stud commander lanes and explicit civic/merchant/spawn reservations.

The renderer resolves `(civilizationId, buildingKind, visualTier)` through a
complete kit manifest. Missing art fails a development assertion rather than
silently showing a generic foreign model. Kits can share primitive helpers and
snap extents but require different structural definitions and function props.
Each manifest entry links an evidence card; the architecture note is an initial
brief, not thirteen certified reconstructions.

Alternative: scale production SettlementDistricts and recolor common buildings.
Rejected because role shapes, footprints and historical distinctions would remain
too generic. Reuse source templates only through sanitized, scaled clones with
captured joints/grips and source fingerprint checks.

### 3. Conservative state and transaction ownership

The sandbox profile is a new domain, not an extension read by ProfileData V1.
Proposed top-level state: `schemaVersion`, per-civilization `coins`, integer
`goods`, bounded `plans`, stable-ID `buildings` (kind, local cell, orientation,
visual tier, integer outputs), owned `workers`/assignments, `research` completion
and remaining project time, `merchant` cycle/stock, and convenience `settings`.
Validate types, finite bounds, unknown IDs, counts, housing, footprints and all
cross-field invariants before activating anything. Unknown/malformed saved data
is an error; never clamp it into a new valid profile and overwrite the original.

Transient state includes active claim/session epochs, current authority,
monotonic production clocks, visible actor lives, request budgets and a bounded
recent-request response cache. Production partial intervals, health, paths,
animations and formations are not persisted. Research remaining active time is
saved separately and can pause without granting offline progress.

Each mutating intent includes a bounded request ID, expected revision and opaque
target identifiers; ownership is derived from the actual sender. Validate
shape/finite integer counts before looking up a target. Verify session, civilization,
claim, life, authority, unlocks, spatial context, funds and capacity, then perform
one non-yielding state transition and increment the revision. Client-supplied
balances, prices, output, finish times and ownership are never accepted.
Repeated accepted request IDs return the stored result; stale revisions/epochs
reject. Bounded per-player operation budgets reject spam without growing queues.

Buying deducts price/stock and adds a plan. Placement removes a plan and adds one
stable building. Collection moves available output into free collected capacity.
Sale removes goods and adds server-priced Coins. Craft completion consumes inputs
and creates goods atomically. All preserve goods or explicitly consume a recipe;
there is no separate client-authoritative visual success path.

Merchant/trade actions require twelve-stud proximity to the owned starter trade
site; building actions require twelve studs from their building target. Research
requires the owned upgraded civic site within twelve studs. Placement uses only
the owned plot within eighty studs of its center. Server distances are in world
studs for the normal-size commander, independent of model scale. Hidden panels
continue the same checks and present a readable out-of-range state.

### 4. Initial balance and active clocks

The proposed numeric catalog is recorded in the linked redesign note's starter
table, research graph and invariants. Implement those values as shared immutable
data with server calculations; do not parse Markdown at runtime. Initial raw
intervals: Food and Timber 10s, Material 15s; yield per worker 2/1/1. The Spartan
recipe consumes one clay and yields one pottery per worker every 15s. Sale prices
are 2/4/6/15 Coins. Role variants need an equivalent explicitly tested budget.
Coin cap remains one billion; any overflowing transaction rejects whole.

Start with 200 Coins, three placed starter structures (civic/trade site, house,
farm), two workers assigned to the farm, and empty goods/plans. House capacity is
four. Limits are eight workers, twelve placed buildings including starters,
twelve unplaced plans and sixty output units per producer. Central collected
inventory is 200 units, or 400 with a unique Storehouse. Plans do not count as goods.

A producer completes whole building batches: `workers × perWorkerYield`. If
that whole batch lacks input or output room, settle no part and reset its clock.
Collection may transfer a partial integer quantity, leaving the rest in output.
At an assignment/rate/capacity change, settle whole eligible work under the old
conditions, then reset its clock. Relocation settles already completed work and
keeps the current partial interval without creating another completion.

Use a bounded shared scheduler rather than per-actor reward loops. At most six
completed batches per producer are considered after a delayed update, then any
older backlog is dropped. This bounds stalls without storing a future windfall.
No active producer consumes output randomness or movement arrival events. Stale
owner/authority stops work before mutation. An inactive/full interval is never
recoverable by moving, collecting, upgrading, switching or rejoining.

Alternative: copy cash-per-second factories, economy multipliers and offline
catch-up from reference guides. Rejected for this slice because it hides the
goods loop, creates stacking risks and conflicts with the preserved active-time
authority boundary. Variable prices and offline rules require later contracts.

### 5. Predictable personal stock and recoverability

Each civilization's merchant owns its own cycle boundary and stock map; UI never
changes inventory. A 180-second cycle replaces stock with farm/house counts of
two each and one of each unlocked advanced plan. A newly completed unlock adds
its plan on the next restock, with that delay shown in the UI. Unique roles are
not repurchasable while placed or held as plans; unlocking never grants one.

Persist cycle identity, next boundary and remaining stock in the fake profile.
Reacquiring before the boundary preserves remaining stock. If one or many
boundaries elapsed, replace stock once for the current cycle, without offline
production, cycle accumulation or a free per-join refill. Use the injected trusted
clock for deterministic tests; do not accept client timestamps. Stock is private
to `(player, civilization)` and never shared across owners.

The starter farm/civic site cannot be unpacked. Housing cannot be removed below
owned-worker capacity. Unpack requires zero workers, empty outputs and room for
the returned plan; storage also checks capacity dependencies. Never exchange a
building/plan back into Coins. The free farm and no-upkeep workers prevent a
zero-wallet softlock. Research presets must not buy workers or move buildings.

### 6. Research graph and automation

Encode the nine-node directed acyclic graph with explicit predecessor IDs,
integer costs/materials, active duration and one exact effect. The three roots
require a purchased hall upgrade. A graph check detects missing predecessors,
cycles, duplicate IDs and unreachable unlocked-plan types. Costs and durations
are 100 Coins/30s, 180 Coins + 10 Timber/60s, 240 Coins/90s down each branch.
No research cancellation/refund UI is included initially.

Only one project runs in the active civilization. Deduct at start, update remaining
active time under authority, then mark completion once before applying its effect.
Pause on switch/leave/lost authority; never read wall-clock absence as research
time. Raw interval reduction is one fixed factor of .9, not a stackable arbitrary
percentage field. Purchased buildings and fighter capacities are separate from
their research unlocks. Presentation slots do not register actors with combat.

Porter Service and Trade Steward call the same bounded transfer/sale transitions
as manual actions, under a fresh context each tick. Sale reserves are integer
per-good minimums; automatic sales cannot remove protected inputs. Manual sales
remain explicit selections. Research never gates basic worker UI, camera controls,
manual sale/collection or accessible navigation. Proposed actor limits are eight
workers, four fighter presentations and one healer presentation per owner.

### 7. UI state follows authoritative revisions

Build on the preview's native GUI style, camera lifetime and PanelVisibility
semantics without importing production purchase flows. Give merchant, inspector,
research and army panels separate logical availability and visibility. Retain
selection/drafts across minimization; invalidate them on target/session changes.
Network receipts update the authoritative snapshot; a ghost or optimistic button
state cannot imply completed construction or sale.

The research graph is original geometry with a list alternative; screenshots
guide information hierarchy rather than copying graphics. Prefer text labels,
branch tabs and restrained faction accents. Use native input checks for purchase,
ghost placement/rotation/cancellation, collection/sale, research, minimization,
focus, camera/respawn and four bounded layouts.

Alternative: duplicate every screenshot button including cash/premium prices,
paid restock and offline-income prompts. Rejected because those would promise
systems absent from this sandbox and obscure the chosen historical goods loop.

## Risks / Trade-offs

- Thirteen kits imply substantial art scope → complete a functional Spartan loop
  first, then evidence-backed kits in small batches, with a per-kit review sheet.
- Landmark sources do not establish vernacular detail → record inference; source
  missing domestic/commercial features before final model acceptance, especially
  Mauryan roofs, 1200s ger detail and Ottoman commercial frontage.
- Active-only production differs from the screenshots → explicit status text;
  revisit offline accumulation as a separate design, not a hidden port.
- Presentation soldiers could look like functioning armies → label the sandbox
  scope in Army UI and do not load damage/healing registrations.
- Clocks, automation and repeated intents can duplicate goods → conservation,
  boundary, race, fake-store reload and fault-injection regressions before native UI.
- Full-size commanders can obscure miniature layouts → nonblocking scenery,
  reserved wide lanes, enlarged query targets and Walk/Overview tests.
- Many actors/buildings can overwhelm the client → fixed caps, shared scheduler,
  existing landscape limit if reused, plus a native eight-settlement static stress
  scene; profile before raising limits or adding combat.
- Civilizations have different historical weapons/economies → equivalent role
  budgets are a declared game abstraction; historical flavor is not a free bonus.

## Migration Plan

1. Add the new mapping and strict dependency allowlist; prove fake-store isolation
   before activating economic mutations. Preserve the original preview and backup.
2. Implement and verify small Spartan slices, then research/UI and thirteen-kit
   rollout. All fixtures inject their stores; no remote publication or real data.
3. Record which native tests ran. Two-owner isolation may use the existing
   simulated multiplayer mechanism after solo ends; never exceed two open Studio
   playtests. Close owned verification windows afterward.
4. Roll back by reopening the unchanged scale preview or production project;
   sandbox fake progress is disposable and cannot overwrite either real store scope.
5. Real storage, combat, public rollout and any V1 migration require subsequent
   changes with explicit compatibility policy and native/published verification.

No unresolved decision blocks this proposed first economy sandbox. Exact visual
ornament within evidence-backed kits and measured economy pacing can be refined
without changing these ownership and conservation contracts.

## October 29 approved interaction revision

This section supersedes the earlier manual management, mixed-resource prices and
civic merchant interactions. It changes only the isolated sandbox.

- Keep `plans` and `goods` as the authoritative building/goods inventory. Hotbar
  selection and inventory visibility are client-session state, never ownership.
  Selecting an owned building starts existing guarded snapped placement.
- Expose `reclaim` in place of Move/Unpack: settle old work, check output transfer
  capacity and dependency/plan limits, transfer the whole output, remove the
  building and return one plan atomically. Civilians are released and allocated
  again. Protect the civic site and last house. The starter farm may be reclaimed
  because its returned plan can be placed for free. Replays cannot duplicate it.
- Each house provides four civilians up to eight. Reconcile population from
  placed housing, preserve existing valid job assignments, and fill remaining
  slots in stable building order. Shrinking housing removes excess civilians
  after old production settles. Do not bank work during reassignment. Persisted
  older fake states remain validated before reconciliation; never repair corrupt
  data into defaults. Legacy pure handlers may remain for historical regression
  coverage; old move/unpack/hire/assign requests are not exposed to clients.
- CollectPrompt uses E and the ordinary guarded `collect` transition with no
  quantity parameter, retaining any output that cannot fit. Clicking a producer
  with the selected hammer invokes reclaim. No management page is necessary.
- Create distinct shared buy/sell stalls outside owned plots. Snapshot positions
  drive client reasons; actual server positions drive purchase/sale distances.
  `travel` accepts only buy/sell/civilization destination IDs, validates current
  life/claim/write authority, and uses server-chosen safe arrivals. No client
  transform is accepted; no balances, goods or production timers reset.
- `sellAll` computes every carried good at fixed server prices, checks wallet
  overflow first, then removes them all and credits Coins once. Empty/failed
  requests change nothing. Building items and the hammer cannot be sold.
- Remove material purchase costs from buildings, the civic upgrade and research.
  Clay-to-pottery still consumes clay as a recipe ingredient, not currency.
- Config.productionSpeed=10 divides the effective producer interval. Base catalog
  rates and the single Organized Work modifier remain explicit. Research/restock
  clocks are not accelerated; all active-time/full-buffer/lease guards remain.
- The top has only Buy / Civilization / Sell navigation; successful travel opens
  its corresponding stall/settlement surface. Inventory/hotbar support click and
  number keys plus B; typing/menu focus suppresses shortcuts. Research/army remain
  reachable from settlement management. Civilian presets are no longer offered;
  Settlement Records is the documented predecessor for Porter Service.

Current native acceptance must use InventoryFlow, covering actual navigation
teleports, stall distance guards, Coin-only purchase, hotbar placement, automatic
housing/jobs, E collection, Sell All, hammer reclaim/replacement and stale or
foreign refusal. Older management fixtures record the prior interaction contract
and must not be cited as new-interface passes. Physical device/publication and
real storage remain separate evidence.

## October29 simple shop, automatic building troops and spaced map

This user revision supersedes the research gates, inspection pages and selectable
roster. Config.researchEnabled=false pauses research/effects/convenience services
and removes their request/UI surfaces. Catalog eligibility is independent of
research; validated legacy research data stays dormant. Missing-only ranged
plan/stock defaults identify an explicit copy-upgrade of older fake records;
seed only genuinely previously locked stock once, never replenish spent stock on
rejoin. Malformed state still fails closed; production V1 is unrelated.

Retain `training` as the legacy melee building ID; add `ranged` with the same10×8
footprint and250-Coin price. `healer` supplies one medic for200Coins. Military
buildings are repeatable under building/plan caps. State.troops derives counts
from placements, while World creates stable per-building actor IDs and removes
only actors belonging to removed buildings. Reclaim automatically removes that
building's figures; military figures never consume civilian job capacity.
Existing saved roster values are compatibility data, not current spawn authority.

ArcheryRanges provides original, culture-specific ranged-yard geometry and
training props at quarter scale. Direct kit factory dispatch supports every
Catalog role; card notes label the inferred practice-yard function. No template
mutation, executable imported models, attack/heal registration or stat bonus.

Build is a small modal with one header/restock label, a three-tab row and scrolling
compact item rows. Every row contains a real civilization model thumbnail, brief
name/function, stock and Coin buy control. Storehouse belongs to Production.
No Civic tab, technical timers/footprints in descriptions, Inspect/roster/research
pages or hall-upgrade controls. Sell is a small Sell All surface; Civilization
travel closes popups. A compact HUD button retains civilization switching. Keep
inventory/hotbar, guarded placement, shared-stall distances and InputReadiness.

World uses Config.worldSize=1200 and Config.plotRadius=400. Existing local
placements retain their local coordinates inside enlarged80×64 starting bounds;
world grounding remains flat. Future160×128reserves are disjoint. Starting space
requires no expansion purchase or research, and actor/building limits and production
caps stay unchanged. Teleports use unchanged server-selected stall
and owned-spawn arrivals, not client coordinates.

Verify catalog eligibility/migration, disabled research, per-building counts and
repeatable military reclamation in deterministic cases. Native checks cover
three-tab compact rows, shared travel/Sell All, buying and placing three troop
buildings with no research, exact2/2/1figures, building-specific removal/rebuild,
all13ranged factories, map bounds/spacing, four layouts and normal respawn input.
Any funded native setup must seed Coins only, leaving research empty and goods
zero; ordinary progress starts at200Coins. Record funded setup distinctly.


Troop-cap clarification: Config.troopCap=10 is a server-owned total across melee,
ranged and medics. State.troopGroups walks stable building order and allocates
whole2/2/1groups only when they fit; a later medic may use a single remaining
place. State.troops sums allocated groups, not demand. World renders only these
building-owned groups. Reclaim frees capacity for waiting groups without raising
the cap or changing civilian jobs. Replacements keep stable per-building IDs;
no new persistent troop counters or client-selected capacity are introduced.
