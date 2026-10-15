# Proposal

## Why

Settlement growth currently offers repetitive purchases at a shared courtyard. Players need useful buildings, visible economic activity and more control over their armies during repeated 30–45 minute sessions.

## What Changes

- Confirmed first milestone: training yard at settlement 5; farmland and worker camp at 7; army camp at 10 adds a selectable third melee/ranged slot. Purchases complete immediately.
- Require Barracks IV, Training Yard I, Farm I and Worker Camp I before entering settlement 10. Hide pads whose progression prerequisites are unmet, while showing missing requirements at the main hall.
- Place weapon/armor pads at an armory, barracks pads at its entrance, and new pads beside their corresponding structures or construction sites.
- Add one connected farming economy: tending workers produce a bounded reserve while their civilization is active, collected at the farm. Save purchases, reserve and extra troop choice separately per player/civilization.
- Implement advance, hold and regroup commands after buying the training yard.
- Proposed tuning: Training Yard 50 coins, Farm 80, Worker Camp 60, Army Camp 120. Farm I earns one coin per five active seconds; Worker Camp I adds a second farmer and doubles that rate. Initial reserve holds 60 coins. Class changes apply at the next respawn.
- Later farm tiers (12/20/30/42), storehouse upgrades, army slots four/five, abilities and specialists remain subsequent milestones. Full level-50 pacing needs playtesting; this change does not claim a measured completion time.

## Capabilities

### New Capabilities

- `settlement-development`: Building purchases, milestone prerequisites and distributed physical pads.
- `farming-income`: Active-civilization income, collection, workers and persistence compatibility.
- `army-commands`: Training commands and selectable reinforcement slots.

### Modified Capabilities

None. Existing gameplay is recorded in earlier unarchived changes; the durable inventory currently contains development-workflow only.

## Impact

Shared progression/catalog rules; profile validation and server economy; settlement/world construction and terrain reservations; army slots and navigation; physical pad authority; client HUD/commands; fake-store module and solo engine tests. No new dependencies, external assets or matchmaking changes.
