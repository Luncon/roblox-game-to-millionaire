# Miniature settlement economy

## Purpose

Provide an isolated miniature settlement loop in which players place owned
buildings, assign workers, produce and collect goods, and sell surplus safely.

## ADDED Requirements

### Requirement: Independent sandbox progression

The playable sandbox SHALL use injected fake storage and separate per-player,
per-civilization state. It SHALL retain thirteen civilization choices and eight
exclusive claimed plots. Production-game data, mappings, backups and the existing
scale preview SHALL remain unchanged.

#### Scenario: Start or switch a sandbox civilization

- **WHEN** a writable fake profile and an available civilization are selected
- **THEN** only that player's selected miniature state is activated
- **AND** a switch preserves the other civilization's balances, goods, plans, placements and research
- **AND** failed loading or a lost lease does not create replacement progress
- **AND** no real player DataStore is opened

### Requirement: Recoverable starter economy

A new sandbox civilization SHALL start with 200 Coins, a civic site, a house
providing four civilians, and a farm automatically staffed by two of them. Initial
goods SHALL be empty. The civic site and last house SHALL be protected. A reclaimed
starter farm SHALL return a free-to-place building item so recovery never needs
combat or another purchase.

#### Scenario: Recover after spending the wallet

- **WHEN** the player has zero Coins
- **THEN** the starter workers can still produce goods for free collection and sale
- **AND** no mandatory upkeep or premium purchase prevents recovery
- **AND** decorative preview soldiers are not counted as a purchased army

### Requirement: Inventory placement and hammer reclamation

Only the current living owner with write authority SHALL place an owned plan
inside the claimed plot. Placement SHALL enforce finite snapped coordinates,
allowed rotations, footprints, overlap and route reservations. Invalid placement
SHALL consume nothing. Relocation SHALL preserve the building identity and state.

#### Scenario: Place a purchased plan

- **WHEN** a valid placement is confirmed
- **THEN** one owned plan becomes one building exactly once without another price deduction
- **AND** canceled, repeated, foreign, overlapping or out-of-bounds requests cannot create an extra building

#### Scenario: Reclaim and replace a working building

- **WHEN** its living owner uses the Destroy Hammer within range
- **THEN** eligible whole work settles, stored output transfers to carried inventory, civilians are released and exactly one building item returns
- **AND** full goods/plan capacity or protected/dependency failures leave the building, inventory and population unchanged
- **AND** selecting the returned item allows ordinary placement without another purchase
- **AND** the interface offers no Move, Unpack or Assign controls

### Requirement: Bounded workforce and inventory

The initial sandbox SHALL cap workers at eight, placed buildings at twelve
including starters, and unplaced plans at twelve. Each placed house SHALL provide
four civilians automatically, bounded by eight; there SHALL be no hiring charge. Collected goods SHALL share a 200-unit cap,
increased to 400 by one Storehouse. Plans SHALL use separate capacity.

#### Scenario: Housing or production demand changes

- **WHEN** a house or producer is placed or reclaimed
- **THEN** valid existing jobs remain and available civilians fill remaining producer slots in stable order
- **AND** assignment stops when no civilian or no job slot remains
- **AND** housing removal reduces population to remaining capacity after old work settles
- **AND** no count exceeds its cap and no manual assignment request is exposed

### Requirement: Authoritative active production

Only the active claimed civilization with write authority SHALL produce goods.
Production SHALL use complete intervals, assigned workers, available inputs and
complete output capacity. Full, inactive or unauthorized time SHALL NOT be banked.
Rate and capacity changes SHALL settle old conditions before resetting clocks.

#### Scenario: Produce a basic farm batch

- **WHEN** two assigned farm civilians complete one active second at the explicit ten-times test speed with sufficient output space
- **THEN** four Food units enter the farm's output and no Coins are awarded
- **AND** collecting later cannot regenerate those units

#### Scenario: Pause a blocked producer

- **WHEN** output is full, inputs are insufficient, or the civilization becomes inactive
- **THEN** no further batch completes and missed intervals are discarded
- **AND** restoring capacity or authority starts a fresh interval
- **AND** offline time and a stalled simulation cannot cause unbounded catch-up

### Requirement: Conservative collection and crafting

Each producer SHALL hold at most sixty output units. Collection SHALL transfer
only goods that fit into collected inventory, preserving any remainder. Crafting
SHALL consume the recipe's full inputs and add its output in one transaction;
full output or insufficient inputs SHALL consume nothing.

#### Scenario: Collect into an almost-full inventory

- **WHEN** ten goods are available but only three collected-inventory spaces remain
- **THEN** three goods transfer, seven remain at the building and no Coins change

#### Scenario: Complete a Spartan pottery batch

- **WHEN** one assigned potter completes one and a half active seconds at test speed with one collected clay and output space
- **THEN** one clay is consumed and one pottery is created exactly once
- **AND** another sale or crafting action cannot spend the same clay

### Requirement: Shared-stall Sell All and Coin-only purchases

The shared sell stall SHALL provide one Sell All action. It SHALL total every
carried good using server-owned prices, check wallet overflow, then remove all
sold goods and credit Coins atomically. Empty/invalid/foreign/stale/out-of-range
requests SHALL change nothing. Building inventory and the hammer SHALL never be
sold. Every currently exposed building purchase SHALL cost Coins only; goods
SHALL NOT be required as currency. Recipe inputs remain goods consumption.

#### Scenario: Sell a mixed inventory

- **WHEN** a valid owner at the shared sell stall sells ten Food and one Timber
- **THEN** all eleven goods leave carried inventory and twenty-four Coins enter the wallet once
- **AND** the client cannot choose prices or sell another owner's inventory

#### Scenario: Buy with no materials

- **WHEN** the owner has enough Coins and stock at the shared buy stall
- **THEN** zero Timber or Grain does not block a building purchase
- **AND** no goods are deducted as purchase currency

### Requirement: Private predictable merchant stock

Each player-civilization merchant SHALL maintain separate stock on 180-second
cycles. Each cycle SHALL offer two farm, two house and two of each repeatable military plan plus one of
each other eligible advanced plan. Restocking SHALL replace unused stock rather than stack
it, with no paid refresh, premium currency or random basic-building availability.

#### Scenario: Buy the last plan in stock

- **WHEN** the owner buys a legal plan with available Coins and plan capacity
- **THEN** the published price and one stock unit are deducted atomically and one plan is granted
- **AND** concurrent or replayed requests cannot overspend or grant duplicate plans
- **AND** another player's stock is unchanged

#### Scenario: Rejoin or return after a cycle

- **WHEN** a fake profile is released and reacquired
- **THEN** stock and the current cycle are restored without a rejoin refresh
- **AND** elapsed cycles grant at most one current stock replacement without offline accumulated stock

### Requirement: Safe restoration and stale-request rejection

The sandbox SHALL validate balances, goods, plans, placements, assignments,
merchant state and research before activating restored progress. Requests SHALL
bind to the current player, civilization, session, claim and revision. Invalid
state SHALL fail closed without clamping or overwriting an existing profile.

#### Scenario: Restore on another plot

- **WHEN** a valid saved miniature civilization is restored to a new owned plot
- **THEN** local placements rebuild relative to that plot without foreign ownership or world-coordinate drift
- **AND** health, animation, partial production time and offline yield are not restored as saved rewards

#### Scenario: Receive stale or malformed traffic

- **WHEN** an old session, stale revision, dead owner, lost authority or malformed numeric payload requests a mutation
- **THEN** no currency, goods, plans, stock or building state changes
- **AND** bounded request handling returns a readable rejection without an unbounded queue

### Requirement: Direct producer collection

An owned producer SHALL expose an E-key Collect All prompt. It SHALL call the
same guarded collection ledger directly, without requiring a management page.
Collection SHALL fill only available inventory capacity and retain the remainder.

#### Scenario: Collect crops in the world

- **WHEN** the living owner presses E at an owned producing farm within range
- **THEN** available crops move to that owner's carried goods inventory without awarding Coins
- **AND** a stale, dead, foreign or unauthorized interaction changes nothing

### Requirement: Explicit fast testing speed

The Studio-only sandbox SHALL expose a ten-times production speed setting and
show that effective speed to the player. Restock SHALL retain its ordinary clock; research is paused. Full, inactive and lost-authority time SHALL still never accrue.

#### Scenario: Watch a fast farm batch

- **WHEN** two staffed farm civilians have one active second and sufficient output room at test speed
- **THEN** four Food are produced once
- **AND** dormant research cannot add another production multiplier

### Requirement: Troops are supplied by their buildings

Each melee building SHALL supply two owned melee figures, each ranged building
two ranged figures, and each healer one medic, subject to army capacity. Multiple
buildings SHALL supply independent groups without civilian jobs or selected
rosters. Figures SHALL remain passive until separate combat/healing work.

#### Scenario: Place and reclaim repeated military buildings

- **WHEN** two melee buildings, one ranged building and one medic building are placed
- **THEN** four melee, two ranged and one medic appear with stable building-owned identities
- **AND** reclaiming one melee building removes exactly its two figures
- **AND** rebuilding the returned item restores its group without a second charge

### Requirement: Fixed army capacity

The total military cap SHALL be ten, including medics. Buildings SHALL NOT raise
it. Whole2/2/1groups SHALL allocate in stable building order, waiting if they do
not fit. Reclaim SHALL free capacity for waiting groups. Civilian capacity SHALL
remain separate.

#### Scenario: More buildings than the current army cap

- **WHEN** placed buildings demand twelve troops
- **THEN** no more than ten military figures appear, including medics
- **AND** a pair waits if only one place remains, allowing a later single medic to fit
- **AND** reclaiming an allocated building frees room for a waiting group without increasing capacity
- **AND** the civilian limit and assignments remain separate

### Requirement: Spacious world with future expansion room

The isolated map SHALL be1200studs square with eight settlement centers on a
400-stud radius. Starting buildable plots SHALL be80×64 with existing local
placements retained. Each plot SHALL have disjoint room for a future160×128 reserve;
that reserve SHALL NOT silently increase current build bounds or actor caps.

#### Scenario: Restore on the larger map

- **WHEN** a civilization restores to its owned plot
- **THEN** its local placements and server-chosen arrivals use the new plot frame
- **AND** every future reserve fits inside the world without overlapping another
- **AND** production maps, Terrain and developer geometry remain unchanged

#### Scenario: Larger starting settlement without expansion research

- **WHEN** a player starts or restores any civilization
- **THEN** its visible plot and shared authoritative placement bounds are80×64
- **AND** buildings fit in the newly available area without an expansion purchase
- **AND** footprints beyond the new boundary, overlaps and reserved lanes remain rejected
- **AND** troop, civilian and building-count limits remain unchanged
