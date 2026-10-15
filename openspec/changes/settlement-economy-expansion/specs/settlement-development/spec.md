## Purpose

Provide useful economic construction and affordable gear choices as settlements advance from their first village toward level sixteen.

## ADDED Requirements

### Requirement: Second economic building tiers
Farm II and Worker Camp II SHALL unlock at settlement 12, costing 180 and 140 coins. Each SHALL require its first tier, and Worker Camp II SHALL require Farm II. Purchases SHALL complete immediately and show their tier on physical pads and buildings.

#### Scenario: Buy workers after improving fields
- **WHEN** a level-12 owner has Farm I and Worker Camp I
- **THEN** Farm II is available while Worker Camp II stays hidden until Farm II is purchased

### Requirement: Separate gear workshops
Blacksmith I and Armorer I SHALL unlock at settlement 13 and cost 150 coins each. The blacksmith SHALL discount weapon prices by 5%, and the armorer SHALL independently discount armor prices by 5%. Final prices SHALL round upward to integer coins and match server purchases, HUD and floor labels. Combat statistics SHALL retain their existing curves.

#### Scenario: Independent prices
- **WHEN** an owner buys only Blacksmith I
- **THEN** the next weapon price is rounded upward after the discount and armor prices remain unchanged
- **AND** damage and maximum health do not increase from the workshop purchase

### Requirement: Distributed expansion sites
New buildings and pads SHALL fit their settlement at unlock and stay clear of later districts, standing areas and troop exits through level 50. Completed or progression-locked upgrades SHALL remain absent. Farm upgrades and collection SHALL use distinct physical pads.

#### Scenario: Level fifty construction
- **WHEN** a civilization owns every level-16 economic building and reaches settlement 50
- **THEN** all available controls remain reachable without intersecting buildings or being replaced by districts
