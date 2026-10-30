# Proposal

## Why

The approved miniature scene establishes the look, but it has no player-driven
building, goods economy or research. Adapt the user's Mini War references into
a civilization-building game whose economy, troops and architecture fit the
existing thirteen historical factions.

## What Changes

Confirmed direction:

- Keep all thirteen civilizations and their established historical periods
  (user confirmation October 28, 2026), eight exclusive claimed plots, normal-size
  unarmed commanders and miniature armies. Keep the current preview's visual scale.
- Use the user's Obsidian reference note, shop/gameplay/research screenshots and
  linked guides as design evidence. Give every building a distinct functional
  design within each civilization's historical architectural language.
- Preserve the production build, version-one player saves, dated backup and
  clean scale-preview project. The shared Black Market stays deferred.

Proposed design choices for review:

- A separate playable miniature sandbox: buy plans from a personal restocking
  merchant, place buildings, automatically employ housed civilians, collect goods with E, sell inventory and
  research improvements. Delivery proceeds through small verified slices.
- Four shop categories: Production, Homes, Military and Civic. Historical farms,
  craft yards and workshops replace modern factories; civic/council halls replace
  technology labs; period-appropriate infantry and missile troops replace modern
  military escalation. Mobility/siege are faction-dependent later content.
- One abstract Coin currency for every purchase, visible goods/building inventory and hotbar, bounded production and
  fixed initial NPC sale prices. A small, fully specified starter economy replaces
  copying the reference game's prices, income multipliers or long research waits.
- A connected Economy / Army / Civic research graph; accessible management UI
  takes the references' information structure while using original art and layout.
- A sourced thirteen-faction building/troop design matrix, equal initial role
  budgets, and separate evidence/review for every faction before its art ships.
- Fake-store-only development first, with a separate miniature profile schema
  behind an injected adapter before any real-storage integration. No automatic
  migration or conversion of legacy balances or levels.

Outside this change's implementation scope: publication, real player-data
migration, player combat, direct player trading, alliances/clans, premium currency,
paid restocks, random generals, offline production, naval/air units and conquest.
The design records future conquest and mobility/siege equivalents, but those need
their own reviewed gameplay changes. Shared territory rewards never become a
required input to a protected settlement's basic economy.

## Capabilities

### New Capabilities

- `civilization-building-kits`: historically sourced, function-specific miniature
  buildings, thirteen distinct architecture kits and faction troop presentations.
- `miniature-settlement-economy`: owned placement, workforce, goods production,
  collection, selling, private merchant stock and isolated progression state.
- `civilization-research`: server-validated connected research unlocks and bounded
  improvements with explicit prerequisites and advancement costs.
- `miniature-management-ui`: Build / Settlement / Trade management, merchant cards,
  placement feedback, building inspection and a navigable research graph.

### Modified Capabilities

None. The implemented main-spec inventory contains development-workflow.
The completed miniature-preview change remains an independent scale sample.

## Impact

Add an explicitly allowlisted playable sandbox project with new game modules
under `prototypes/miniature/game/`; retain the existing preview and production
mappings. Reuse immutable appearance templates and selected visual helpers only
after scale/lifetime tests. Add deterministic Lune logic fixtures, native Studio
interaction fixtures and a two-owner fake-store isolation run when needed.

Design rationale and sources live in
[`docs/notes/Miniature Civilization Redesign.md`](../../../docs/notes/Miniature%20Civilization%20Redesign.md)
and the linked historical building matrix. This proposal changes no game code.

## October 29 interaction revision — confirmed user requirements

Use the saved Mini War screenshots as an interaction reference: exactly three
main top buttons, Buy / Civilization / Sell, teleport to the shared buy stall,
owned settlement and shared sell stall. Purchases occur at the buy stall and
Sell All converts carried goods at the sell stall. All purchase/research prices
are Coins only; goods are inventory items or recipe inputs, never a second
purchase currency. The merchant retains private per-civilization stock.

Inventory includes returned/unplaced buildings and collected goods. A session
hotbar selects the Destroy Hammer or an owned building. Hammer reclamation
returns one building item for placement rather than using Move/Unpack buttons.
Houses supply civilians automatically; available civilians fill producer jobs
without Hire/Assign buttons. E at a producer collects all that fits directly.
Test production runs ten times faster; this is explicit prototype tuning.
Existing architecture, fake storage, server authority and production isolation
continue to apply. The original 34-task evidence is historical; new acceptance
is tracked in task group 9.

## October29 simple shop and building troops — confirmed revision

Pause research for the current prototype: every production, housing, storage and
military building is purchasable without research. Use the saved shop screenshot
as a compact visual reference: exactly Homes / Production / Military tabs and a
scrolling list with structure image, Coin price and a short everyday description.
Buy/Sell travel opens small shop surfaces; Civilization only returns home and
closes popups. Remove Inspect, research, hall-upgrade and training-roster controls.

Each placed military building supplies its own automatic faction troops: melee
barracks2melee, ranged barracks2ranged, medic post1medic. Multiple buildings each
provide their own group; no player-selected roster numbers. Add a distinct ranged
building role to all13kits. This changes spawning/presentation, not combat AI,
damage or healing. Preserve source models and authoritative building ownership.

Enlarge the isolated map to1200studs square and place the eight settlement centers
400studs from the middle. Increase starting buildable areas to80×64 and reserve room
for160×128future expansion without implementing that expansion yet. Keep all13
identities, fake storage, production mappings, backup and clean preview unchanged.

The enlarged starting plots replace the initial40×32 bounds following playtest
feedback. Keep existing local placements; a paid expansion option remains future
work, and no research or purchase is needed for this starting space.


Clarification: the current army limit is ten total troops, including medics,
independent of how many troop buildings are placed. Buildings supply their own
groups but never increase capacity. Extra groups wait for space; future research
may change the limit, but no such research is active now. Civilians are separate.
