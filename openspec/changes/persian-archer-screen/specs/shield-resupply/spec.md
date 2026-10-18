## Purpose

Let recalled shield troops visibly replenish spent equipment at their settlement instead of requiring a new troop life.

## ADDED Requirements

### Requirement: Unlocked physical shield rack
Each civilization with purchased shield training SHALL display an inert rack of shields beside its training camp. Locked, unsupported or unclaimed settlements SHALL not display it. The rack and approach SHALL be accessible on every rotated plot without blocking camp, controls or the council entrance.

#### Scenario: Buy shields
- **WHEN** Sparta, Rome or Persia purchases shield training
- **THEN** its training area gains a visible shield rack that survives progression rebuilds and disappears when the claim is released

### Requirement: Regroup resupply trip
Recalled living shield melee with zero remaining charges SHALL walk to an assigned pickup at their own rack, receive exactly one fresh two-hit shield upon arrival, then return to camp. Troops with remaining charges, ranged troops and medics SHALL regroup normally. Advance or Hold during the trip SHALL cancel pickup travel.

#### Scenario: Replace a spent shield
- **WHEN** a shieldman's shield breaks and Regroup is commanded
- **THEN** that same life first visits its rack, visibly regains a two-hit shield and continues to its camp position

#### Scenario: Retain partial shields
- **WHEN** a recalled shieldman still has one charge
- **THEN** it returns directly to camp and keeps that one charge

### Requirement: Authoritative limited replenishment
Pickup SHALL require current ownership, supported civilization, purchased training, a living melee troop, writable progress, Regroup and physical proximity to the assigned rack point. Remote, foreign, interrupted or repeated pickup SHALL not grant charges. Ordinary equipment rebuilds SHALL not refill shields. Resupply SHALL preserve troop life, health, skill cooldowns and pending respawns and SHALL not resupply players.

#### Scenario: Cancel before reaching supplies
- **WHEN** a distant troop is ordered to Advance or Hold, loses authority, or changes civilization before arrival
- **THEN** it receives no replacement shield from the old trip
