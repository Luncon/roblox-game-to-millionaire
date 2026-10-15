## Purpose

Extend active farming with gradual production and storage improvements while preserving separate saved reserves and safe online-only timing.

## ADDED Requirements

### Requirement: Improved active production
An active owned farm SHALL produce its farm level plus worker-camp level coins per five seconds, with Farm II and Worker Camp II yielding four. Changing production tiers SHALL first settle completed intervals at the previous rate, then reset the unfinished interval. Inactive or nonwritable profiles SHALL not produce income.

#### Scenario: Upgrade partway through a production interval
- **WHEN** a player upgrades Farm I to II after seven active seconds with Worker Camp I
- **THEN** two coins are credited for the completed old-rate interval
- **AND** the next improved interval begins at purchase time

### Requirement: Storehouse reserve capacity
Storehouse I SHALL unlock at settlement 16, require Farm I, cost 140 coins and increase the uncollected reserve limit from 60 to 180. Capacity upgrades SHALL not credit time spent full. Collection SHALL preserve overflow that cannot fit in the wallet.

#### Scenario: Expand a full reserve
- **WHEN** an owner buys a storehouse after their farm has remained full at 60
- **THEN** the reserve stays at 60 at purchase and only newly completed active intervals can grow it toward 180

### Requirement: Additive economic saves
Farm and worker levels through II, workshop and storehouse ownership, and the expanded reserve SHALL save independently per player and civilization. Missing new fields SHALL default to zero without resetting old values. Explicit malformed tiers, premature buildings or reserves above the owned capacity SHALL block unsafe profile loading.

#### Scenario: Reload an older profile
- **WHEN** a valid first-milestone profile without workshop or storehouse fields loads
- **THEN** its existing purchases, reserve and coins remain unchanged and the three missing building fields become zero

#### Scenario: Saved capacity mismatch
- **WHEN** a saved civilization has 100 reserved farm coins and no storehouse
- **THEN** validation fails without overwriting it with a fresh profile
