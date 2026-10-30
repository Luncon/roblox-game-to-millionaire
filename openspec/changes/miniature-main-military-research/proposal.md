# Proposal

## Why

The user has chosen the miniature game as the main Clash of Civilizations build and supplied an expanded military research guide. Players need meaningful army upgrades and building-based army commands within the current miniature economy.

## What Changes

- **BREAKING**: make `default.project.json` launch the miniature game; preserve the previous mapping as `legacy-fullscale.project.json` and retain dated backups.
- Implement 29 military research nodes from the user's table, adapting modern vehicle upgrades to mounts and names to the civilization theme. Preserve the listed prices, times and prerequisite paths as initial tuning.
- Add server-owned per-civilization research payment, active-play timers and additive troop stat/capacity upgrades. Leave civilian and modern-unit unlock research as grey placeholders.
- Add a pannable hex research interface and Army Control with an all-troops Army 1 plus up to three editable, disjoint building-based groups and an outpost deploy chooser.
- Adapt the hotbar to Inventory 1, Destroy Hammer 2 and unlocked Army Control 3; show held goods/buildings in an image grid with stack counts.

Confirmed requirements are the main-build switch, military guide, grey civilian half, army controls and inventory reference. Additive tier stacking, one research project per civilization and active-play-only timers are implementation choices consistent with existing paused production clocks. Public deployment and real persistent storage migration remain outside this change; Studio development still injects FakeProfileStore.

## Capabilities

### New Capabilities

- `miniature-military-research`: timed military research, troop modifiers and hex presentation.
- `miniature-army-control`: editable building groups and explicit outpost deployment.
- `miniature-inventory-hotbar`: image inventory and dedicated inventory, hammer and army slots.

### Modified Capabilities

- `development-workflow`: default miniature and explicit legacy project mappings.

## Impact

Miniature state validation/migration, requests, active clocks, army simulation and native UI; optional original combat range hooks with unchanged legacy defaults; Rojo mappings, test generators, deterministic/native verification and shared Obsidian documentation. No tool/dependency upgrades, public publishing or real profile access.
