# Design

## Context

See proposal.md. Existing Sessions validates schema-one miniature profiles, owns claims, and uses a 60-second lease with 15-second autosaves. Runtime settles active research before closing. Both currently reject real stores and Runtime rejects live servers. The old published place runs ServerScriptService.Game.Bootstrap. Existing miniature automated fixtures must remain fake-only.

## Goals / Non-Goals

Use the existing save/state model and server authority. Add reliable real storage without a new gameplay system, legacy data conversion, dependency upgrade or destructive data reset.

## Decisions

- Add a thin server-side DataStore adapter with the existing UpdateAsync contract. Use MiniatureCivilizationProfilesV1 / Live and player:<UserId> keys; preserve CivilizationProfilesV1 verbatim. A separate explicit verification scope is permitted for real-storage verification. Local Studio uses its injected fake store; a dedicated production mapping excludes fake modules, so its Studio preview must fail closed or use an explicitly isolated verification adapter.
- Keep server-only trusted store markers: isFakeProfileStore for Studio fixtures, isPersistentProfileStore for the reviewed adapter. Sessions accepts either contract; Runtime rejects fake adapters outside Studio. Store keyPrefix defaults to the old miniature-development: prefix only for fake fixtures, preserving existing tests.
- Generate lease timestamps inside every replayed UpdateAsync callback, use terminal local authority loss, retain/reconcile an acquisition token after uncertain acknowledgements, and serialize saves. Releases never overwrite a successor's lease. Validate values before admitting gameplay.
- Runtime exposes profileStatus, profileReason and lastSavedAt alongside its existing snapshot. Bounded automatic load retries recover transient failures; terminal failure remains unavailable with rejoin guidance. The status UI does not send purchases or grant authority. Rejoin waits for prior same-user close; lifecycle hooks install before existing-player loads are spawned. Shutdown has a shared deadline and reports incomplete saves.
- Add a dedicated release project generated from the main mapping, with a live-only Bootstrap and no FakeProfileStore or fixture scripts. Keep default local mapping functional as a preview; production and local use the same actual gameplay modules.
- Test destructive/error scenarios with fake stores only. Verify the adapter separately against a unique non-live verification scope/key; no regression runner uses player data. Native tests retain original models and behavior. Save a prior place backup before replacing the published target through authenticated Studio.

## Risks / Trade-offs

- Incompatible legacy progression → keep both stores, start independent ordinary miniature profiles, document the boundary.
- Network acknowledgements can fail after a write commits → retry with the same token and verify current ownership; never assume a thrown write did not happen.
- Native multiplayer cannot guarantee a particular faction wins → require truthful capture/combat observations, record the prior timed-out Roman takeover without claiming balance proof.
- Some imported assets already warn about approvals → inspect native rendering and record any remaining asset issue.
- No authenticated publishing route or live client available → finish/test/build everything possible and report the exact external limitation; never claim publication from a build alone.

## Migration Plan

Validate storage/session fixtures, full development checks and native startup. Build and inspect the release closure; back up the target's current place. Verify real-storage roundtrip using an isolated verification scope. Publish only to the recorded authorized target and record version evidence. Test fresh published server and rejoin persistence. Roll back by republishing the preserved old place; neither store is deleted or rewritten by rollback.
