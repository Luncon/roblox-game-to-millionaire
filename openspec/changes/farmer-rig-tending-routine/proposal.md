# Proposal

## Why

The farm tenders currently sway beside the fields rather than tending crops. The user added an R15 farmer model in Studio and wants that character to walk through the crops on a repeatable routine.

## What Changes

- Use the supplied `Workspace.Farmer` appearance for passive farm tenders, preserving its clothing, mesh body and hat in an immutable repository asset.
- Give tenders slow walking routes through the crop rows, row-end turns and short tending pauses. Stagger workers within the existing two fields.
- Preserve the existing one/two/three tender counts, farm income, purchases and save fields. Movement remains decorative, server controlled and outside combat.
- Proposed implementation choice: animate anchored visual clones procedurally with a disabled appearance-only Humanoid and without imported behavior scripts. Routes follow the current plot frame and farm tier.
- Outside scope: crop harvesting mechanics, new farm tiers, farmer combat, new income rules, player commands or changes to army behavior.

## Capabilities

### New Capabilities

- `farm-tenders`: Supplied farmer appearance, passive crop-row routines and their lifecycle within purchased farms.

### Modified Capabilities

None. The main specification inventory currently contains only development-workflow; existing farming implementation and change artifacts supply the compatibility baseline.

## Impact

Adds a farmer asset and Rojo mapping, a farm-tender visual/routine module and focused tests. Updates SettlementInfrastructure and farming documentation. Existing server economy, combat registration and fourteen persisted scalar fields remain unchanged. Verify articulated movement and complete route cycles in the existing Studio window with fake profiles.
