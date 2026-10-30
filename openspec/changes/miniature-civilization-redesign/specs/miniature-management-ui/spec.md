# Miniature management UI

## Purpose

Provide compact shared shops and building-item controls guided by the user's
Mini War shop and navigation screenshots, with plain descriptions and no manual
inspection, research or troop-roster management.

## ADDED Requirements

### Requirement: Compact travel navigation

Exactly three main top buttons SHALL request server-owned travel: Buy,
Civilization and Sell. Buy SHALL open a compact shop at the shared buy stall;
Sell SHALL open a small Sell All surface at the shared sell stall. Civilization
SHALL return to the owned settlement and close popups without opening a large
settlement page. A small HUD action SHALL retain civilization selection.

#### Scenario: Return to the settlement

- **WHEN** a living owner presses Civilization
- **THEN** the server chooses the owned spawn and existing progress remains
- **AND** shop popups close without a settlement-management modal

### Requirement: Three-tab reference shop

The buy shop SHALL have exactly Homes, Production and Military tabs in one row.
Its scrolling list SHALL show the active civilization's actual structure image,
name, Coin price, stock and brief everyday function. Storehouse SHALL appear in
Production. Descriptions SHALL avoid implementation details. Research SHALL NOT
be a requirement or locked reason in this prototype.

#### Scenario: Buy a military building without research

- **WHEN** the owner views Military with no completed research
- **THEN** melee, ranged and medic buildings have ordinary eligible stock and prices
- **AND** each compact row identifies its automatic troop group in plain language
- **AND** only funds, stock, item capacity, ownership and stall guards can refuse a legal purchase

### Requirement: Essential surfaces only

The current interface SHALL NOT provide Inspect buttons/pages, research or hall
upgrade panels, manual civilian assignment, troop counts to choose, training
roster controls or Move/Unpack buttons. Producers SHALL collect through E;
Destroy Hammer SHALL reclaim through owned building interactions. Civilization
selection, inventory, placement, sale and camera controls remain usable.

#### Scenario: Activate a building normally

- **WHEN** a player clicks a building without the hammer
- **THEN** no inspection page appears
- **AND** the producer E prompt or selected hammer supplies the applicable action

### Requirement: Guarded item placement and reclamation

Inventory SHALL show carried goods and owned building items. Hotbar click/number
selection and B inventory access SHALL retain access to every item even when
there are more kinds than hotbar slots. Legal placement consumes one item only
on server acceptance; cancel consumes nothing. The hammer SHALL return eligible
buildings and conserve stored output, with readable dependency/capacity refusals.

#### Scenario: Reclaim a troop building

- **WHEN** the owner uses the selected hammer on a military building
- **THEN** that building returns as one item and its own figures disappear
- **AND** unrelated buildings, figures, goods and Coins are preserved

### Requirement: Independent visibility and input guards

Minimization SHALL retain inventory drafts and logical availability while owner,
life, range, authority and civilization checks continue. Shortcuts SHALL yield to
text/menu focus. Death or switching SHALL clear stale placement/item selection.
The actual game context SHALL initialize normal input readiness; tool fixtures
SHALL NOT create a competing PlayerModule controller.

#### Scenario: Respawn while placing

- **WHEN** a real owned life ends with a building draft
- **THEN** the new life retains items/progress but clears ghost and selection
- **AND** ordinary movement and camera recover without custom movement bindings

### Requirement: Compact native layouts

The shop, sell surface, HUD and controls SHALL fit320×360,320×568,640×360 and
1024×768, with scrolling and at least44×44primary action targets. Native input
and captures SHALL be reported separately from physical phone/controller and
published-client verification.

#### Scenario: Open a compact shop

- **WHEN** the owner opens Buy on a supported layout
- **THEN** the three tabs, image rows, prices and buy controls fit with scrolling
- **AND** shop/close/navigation controls do not overlap primary actions
