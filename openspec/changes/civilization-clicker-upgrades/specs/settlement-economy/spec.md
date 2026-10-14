# Settlement economy

## Purpose

Give settlement owners a responsive single-coin clicker and visible expansion
goals while keeping earning and purchases authoritative on the server.

## ADDED Requirements

### Requirement: One coin per activation

Claimed players SHALL start with zero coins and earn exactly one coin per
accepted activation of their physical coin button. Unclaimed players SHALL NOT earn coins.
Clients SHALL NOT choose the award, target player, or balance. Foreign, distant,
and dead players SHALL NOT activate the owner's pads.

#### Scenario: Rapid legitimate clicks
- **WHEN** an owner activates their ground coin button ten times in one second
- **THEN** the server awards ten coins and the UI shows its confirmed balance

#### Scenario: Malformed or excessive events
- **WHEN** a client attempts a foreign or distant activation, an invalid action, or excessive requests
- **THEN** rejected requests award no coins and do not change ownership

### Requirement: Atomic sequential upgrades

The physical settlement upgrade pad SHALL purchase expansions. Settlement level SHALL start at 1 and increase sequentially to 4. Costs SHALL
be 25, 75, and 150 coins. The server SHALL verify ownership, funds, and the next
level, and deduct its price atomically. Upgrades SHALL NOT increase coins per click.

#### Scenario: Buy a first expansion
- **WHEN** an owner with 25 coins purchases the next upgrade
- **THEN** the balance becomes zero and the settlement becomes level 2
- **AND** its foundation and building count increase visibly

#### Scenario: Reject insufficient funds or maximum level
- **WHEN** an owner lacks the next price or is already level 4
- **THEN** the purchase fails without changing coins, level, or settlement geometry

#### Scenario: Duplicate purchase submission
- **WHEN** multiple character parts touch a pad during the same standing entry
- **THEN** the same entry cannot deduct money or advance another level again until the player exits and re-enters

### Requirement: Confirmed economy interface

The read-only owner HUD SHALL show confirmed coins, current levels, next costs
or maximum levels, and actionable failure feedback. Physical upgrade pads SHALL
show their costs and affordability colors and support clicking, interaction
prompts, and one purchase per walk-on entry. UI SHALL stay usable
on narrow screens and survive character respawns.

#### Scenario: Rejected or delayed purchase
- **WHEN** a purchase fails or the response is delayed
- **THEN** the UI shows guidance without predicting a new level or losing earned coins

### Requirement: Explicit session-only progress

Coins and upgrades SHALL survive character respawns and be isolated per player.
They SHALL reset when the player leaves. The interface SHALL state that saving
is not implemented yet; no stored progress SHALL be read or overwritten.

#### Scenario: Leave and return
- **WHEN** a player returns after leaving the server
- **THEN** the player begins with zero coins and level 1 after selecting a civilization
- **AND** the interface states that this milestone is session-only


### Requirement: Separate weapon and armor progression

Weapon and armor tiers SHALL each start at 1 and advance independently to 4,
with prices 15, 50, and 125 coins on their own physical pads. A purchase SHALL
only change its own track and balance. Stale or unaffordable purchases SHALL
leave all tracks unchanged.

#### Scenario: Upgrade a weapon without buying armor
- **WHEN** an owner buys the first weapon tier for 15 coins
- **THEN** weapon tier becomes 2 and armor and settlement levels stay unchanged
- **AND** the player receives the upgraded civilization weapon

### Requirement: Equipped civilization gear

A claimed player SHALL receive a civilization-themed weapon and armor. Weapon
upgrades SHALL change the visible tier and configured damage; armor upgrades
SHALL change visible gear and maximum health. Character respawns SHALL restore
owned tiers. Weapon damage SHALL be marked as reserved for the future combat milestone.

#### Scenario: Purchase armor and respawn
- **WHEN** an owner buys armor tier 2 and resets their character
- **THEN** the themed tier-2 armor and weapon remain equipped after respawn
- **AND** standard base health 100 becomes maximum health 120
