# Design

## Context

The server currently owns one session-only Economy account and immutable ClaimRegistry claim per player. CivilizationService publishes scalar attributes and global availability; the selector hides after claim. Existing armies already support restored tiers through refresh. See proposal.md and the two capability specs for behavior.

## Goals / Non-Goals

Use one profile owner and one serial storage queue per player. Keep normal clicks and combat entirely in memory. Restore scalar progression through existing map, equipment and army paths; avoid persisting transient world instances. Server routing and formations remain subsequent milestones.

## Decisions

- ProfileData validates a version-one envelope with a civilization-keyed dictionary of five scalar progress fields. Missing profile and missing civilization are legitimate new states; malformed/future data is rejected rather than normalized into destructive defaults. One player key makes multi-civilization saves atomic and reduces requests compared with separate keys.
- ProfileService owns UpdateAsync acquisition, a unique expiring lease token, validated profile copies, dirty revisions, serialization, retries, autosaves and final release. Default tuning is a 120-second lease, 30-second periodic save and three bounded backoff attempts. Every later write requires the exact original token and a valid lease; nil is not permission to resume an old session. Absolute snapshots make uncertain write retries idempotent.
- A save captures its snapshot after taking the per-player queue. Acknowledging an older revision cannot clear newer pending changes. Release freezes immediately and saves the latest state after any earlier operation. Shutdown freezes gameplay and drains profiles in parallel within the engine shutdown allowance.
- Economy accepts validated initial scalar state and an optional server mutation predicate. Imports get monotonically increasing local revisions; stored revisions, cooldowns and click tokens are excluded. Loading, closing, lost or expired profiles reject coin earning, purchases and kill credits independently of UI state.
- ClaimRegistry gains an atomic switch operation that checks the destination first and preserves the plot. CivilizationService captures old state, switches without yielding, replaces the economy with the target profile, removes old army/combat actors and rebuilds the same plot. Unavailable choices leave the current state intact.
- Loading is asynchronous with player-identity/lifecycle guards. Late load results cannot claim a plot for a departed player; any acquired lease is finalized. A retry action is allowed only without a live claim. Profile status is replicated through player attributes; full saved previews are sent only to that player, while global broadcasts retain availability only.
- The HUD gains a change-civilization control in its existing title row, reserving width in desktop and compact layouts. The selector can reopen and cancel, displays saved progress and availability, and remains disabled until the profile is writable. Session-only wording becomes actual loading/saving/error status.
- Production startup obtains CivilizationProfilesV1 with separate Live and StudioDevelopment scopes. The isolated test project overrides only its bootstrap to inject a fake store; production bootstrap remains unchanged. Fake tests exercise failures and concurrency deterministically; real storage restoration is verified separately when Studio API access is available.

## Risks / Trade-offs

- Storage failure or shutdown interruption can leave the last periodic snapshot as the recovery point. Report actual save state, use final retries and preserve original data on failed loads; do not promise crash-proof saving.
- Rapid departure/rejoin can encounter a live lease. Show profile-in-use/loading feedback and allow bounded retries without stealing an active session.
- Restoring low-tier armor or changing civilization invalidates old actors and gear. Release old registrations before rebuilding and retain character-generation checks around yielding spawn work.
- Existing regressions assumed fresh session profiles. Inject a fresh fake store for each isolated run and share it only within dedicated restoration checks.
- HUD density and long civilization names can clip. Reserve switch-control width, inspect actual TextFits/bounds and take viewport screenshots.

## Migration Plan

There are no prior persistent profiles. New version-one profiles begin only on successful missing-key reads; current session-only progress is not retroactively recoverable. Deploy through Rojo and restart Play. A rollback must leave stored profiles untouched; do not delete keys or rewrite them into session-only defaults.

## Sources

- https://create.roblox.com/docs/cloud-services/data-stores
- https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing
- https://create.roblox.com/docs/cloud-services/data-stores/best-practices
- https://create.roblox.com/docs/reference/engine/classes/DataModel#BindToClose
