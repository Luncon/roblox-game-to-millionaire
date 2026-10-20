# Design

## Context

See proposal.md. CivilizationUI owns claimed/choosing visibility; EconomyUI lays out its HUD. ArmyUI currently couples availability to HUD.Visible. Building menus currently stop checking their context whenever the overlay is hidden. Five independent render paths therefore need one small client visibility helper.

## Goals / Non-Goals

Keep existing direct child paths and authoritative data flow. Use existing colors/fonts and native TextButton.Activated. Avoid a new window manager, animations, global shortcut or saved preferences. No server changes or real-storage fixtures.

## Decisions

- A client helper owns each panel surface's physical visibility, logical open state, minimize button and sibling restore tab. Callers update logical availability; hiding the HUD does not revoke army availability.
- Keep panel contents alive and updating while minimized. Existing form drafts and scrolling stay in place; menu open events explicitly restore. Normal close removes the tab.
- Contextual heartbeat checks use logical open state, including while minimized. Preserve existing proximity/life/civilization guards and server checks. Civilization selection hides gameplay contexts as before.
- Restore HUD/army tabs inside their old panel footprint, selector at top center and building tabs below the HUD. This avoids a global dock covering other panel headers. Reflow header controls and the skill button where needed for narrow/landscape layouts.
- Keep state on the client for this UI lifetime (ResetOnSpawn=false). Transfer selected focus to the restore control and back to a still-available panel control; clean up connections and tabs with their owning surface.

## Risks / Trade-offs

- Repeated render callbacks could reopen panels -> single helper controls visibility and exposes logical availability separately.
- Hidden overlays could leave stale building actions -> heartbeat guards continue against logical openness and server guards remain unchanged.
- Narrow screens could clip or overlap controls -> native input tests and bounded portrait/landscape layout checks, including restore controls and skill placement.

## Migration Plan

Verify in an isolated fake-store Studio client, then sync verified client sources into main Studio in Edit mode. No data migration, dependencies or publication. Published hardware-specific touch/controller input remains a separate check from native virtual input and bounded layout fixtures.
