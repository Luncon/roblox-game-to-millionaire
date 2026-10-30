# Civilization research

## Purpose

Keep the earlier research catalog and validated fake progress dormant while the
current miniature prototype makes every building and resource available directly.

## ADDED Requirements

### Requirement: Research is paused in the current prototype

The sandbox SHALL run with researchEnabled=false. All catalog building types
SHALL be eligible without hall upgrades or research. The runtime SHALL expose no
research, hall-upgrade, roster or research-service mutation request. UI SHALL
show no corresponding purchase requirements or research controls.

#### Scenario: Begin a fresh civilization

- **WHEN** a new civilization activates with no research and its initial Coins
- **THEN** every buyable building has ordinary research-independent eligibility
- **AND** production and military access do not require a research project

### Requirement: Dormant legacy research is conserved

Validated saved research, roster and convenience settings SHALL remain compatible
fake data. While research is disabled, projects SHALL NOT advance, completed
nodes SHALL NOT modify production or capacity, and research services SHALL NOT
collect or sell goods. Their data SHALL NOT be silently erased or grant free stock
repeatedly. Malformed legacy records SHALL still fail closed.

#### Scenario: Restore previously researched progress

- **WHEN** an older valid fake civilization with completed work research and an active project restores
- **THEN** its catalog access is already open but no research modifier or project progress applies
- **AND** its carried goods, Coins and saved research data are preserved

### Requirement: Safe one-time catalog upgrade

A missing-only ranged item/stock upgrade SHALL operate on a validated copy of an
older fake record. Only genuinely previously locked plans SHALL receive their
first ordinary eligible stock. Spent stock SHALL NOT refill on rejoin, and
production ProfileData V1 SHALL remain untouched.

#### Scenario: Rejoin after buying a newly available building

- **WHEN** a migrated owner spends a military stock item then restores again before restock
- **THEN** the remaining stock is retained without another migration refill
- **AND** invalid or partial malformed new fields cannot be replaced with fresh defaults
