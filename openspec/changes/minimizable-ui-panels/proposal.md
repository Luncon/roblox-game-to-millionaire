# Proposal

## Why

The gameplay panels obscure the battlefield and cannot all be tucked away. Players need to minimize screens temporarily and restore their current contents without reopening menus or losing drafts.

## What Changes

- Add minimize and labeled restore controls to all five confirmed panels: settlement HUD, army controls, civilization selection, Barracks recruitment and War Council.
- Hide minimized menu overlays so gameplay remains usable. Keep HUD and army minimization independent, preserve drafts and refresh current state while minimized.
- Retain contextual menu proximity/life/civilization guards while minimized; closed menus leave no stale restore tabs.
- Proposed defaults: client-session preferences only, expanded on initial open, existing visual style and native button activation for mouse/touch/gamepad. Keep controls reachable in narrow and landscape viewports.
- No server authority, saved profiles, currencies, combat or new gameplay commands change. The small weapon skill control remains usable.

## Capabilities

### New Capabilities

- `panel-visibility`: independent local panel minimization, restoration, contextual closure and accessible responsive controls.

### Modified Capabilities

None; the main inventory currently contains only development-workflow.

## Impact

Client panel modules, a small shared client helper, native input/layout fixtures and UI documentation. No dependencies, remotes, persisted fields, assets or publication.
