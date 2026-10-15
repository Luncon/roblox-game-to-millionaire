# Proposal

## Why

The first development milestone provides useful buildings through settlement 10, but later purchases remain mostly settlement and gear levels. The next slice adds economic choices and visible construction through level 16 while keeping combat scaling gradual.

## What Changes

- Extend the agreed roadmap with Farm II and Worker Camp II at 12, separate blacksmith/armorer buildings at 13 and Storehouse I at 16. Retain immediate physical purchases, hidden locked pads and separate civilization saves.
- Add the agreed barracks speed purchases at settlement 8 and 14, yielding Barracks V/VI with 13/12.5-second future respawns. Keep two barracks slots plus the existing selectable camp slot.
- Initial tuning: Farm II 180 coins, Worker Camp II 140, Blacksmith I 150, Armorer I 150, Storehouse I 140, Barracks V 200 and VI 300. Each workshop discounts its own gear track by 5%, rounding prices upward to whole coins; damage and health curves stay unchanged.
- Farm production becomes farm level plus worker level coins per five active seconds (four with both II). Storehouse I raises the reserve limit from 60 to 180. Settle upgrades at the previous rate/capacity, with no offline or capped-time catch-up.
- Expand saved fields additively, preserving old balances, purchases, selection and pending army timers. Add visibly richer fields, another farmer, workshops and a themed storehouse beside their upgrade controls.
- Later farm tiers, storehouses II+, infirmary at 19, checkpoint 20, more army slots and full level-50 pacing remain subsequent work.

## Capabilities

### New Capabilities

These paths extend capabilities first recorded in the completed, unarchived settlement-development-milestone. They are not yet present in the durable inventory; this change adds distinct requirements at the same paths rather than duplicating the original contracts.

- `settlement-development`: Tier-II economic buildings, separate workshop discounts and accessible construction sites.
- `farming-income`: Improved production, storehouse capacity and additive saved tiers.
- `army-commands`: Additional barracks speed tiers with unchanged slots and pending deadlines.

### Modified Capabilities

None in the current durable inventory, which contains development-workflow only.

## Impact

Shared progression and offers; economy/profile validation; settlement infrastructure, district reservations and floor pads; owner HUD/public state; fake-store module and ordinary solo engine tests; gameplay/setup documentation. No new dependencies, marketplace assets, client currency remotes, matchmaking or construction timers.
