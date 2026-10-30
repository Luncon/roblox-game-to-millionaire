# Military research thorough test pass

October29,2026. Follow-up requested after implementation commit `5670d75`.
The expanded regression pass is complete. No new gameplay defect was reproduced.
Added48 deterministic regression cases plus repeatable native fixtures; gameplay
code is unchanged by this testing pass.

The user's existing Studio Play is preserved. One separate research test place
uses only injected FakeProfileStore and an explicitly declared100,000-Coin seed.
It does not read player DataStores. Any commander death used to test lifecycle
guards is confined to that isolated verification session.

## Executed

- Initial committed-change development gate: pass34 specifications,9 Node checks,
  399 Luau syntax files,244 original logic cases,177 miniature cases and immutable
  animal template audit. Changed-file checks explicitly include commit `5670d75`.
- Native original troop factory/solver matrix: all13 civilizations,39 owned
  roles plus2 neutral roles,518 grounded poses and518 client solver poses; source
  templates unchanged and five imported melee outfits retained.
- Native mounted matrix: all13 riders,156 grounded poses,294 client poses,
  129 anatomy joints; lion seating, wolf eyes, bull legs, rhino face and crocodile
  foot sweep passed. Source templates unchanged.
- Native mounted facilities: all13 civilization structures passed.
- Native support collision: all8 plots; commander unblocked, corpses grounded,
  and query/raycast exclusions passed.
- Native ragdoll source lifecycle: exact life, stale-life rejection, bounded
  retirement, unchanged respawn authority, and capture-removal deaths passed.
- Native owner isolation: two concurrent simulated owners and a third identity;
  foreign requests rejected, exclusive claims and paid progress restored. This
  is a native fake-store simulation, not a physical multiplayer-client test.

## Additional executed checks

- New adversarial deterministic suite:41 passing cases, including all29 independently
  recorded prices/times/prerequisite transactions, malformed/cyclic/deep/wide
  payload rejection, replay/rate/stale-claim guards, fractional active clocks,
  independent civilizations, failed fake-store writes and lost acknowledgements.
- Real input/clock lifecycle: five inactive seconds in Rome did not advance
  Sparta's paid project. During commander death, remaining time stayed exactly
  7.4006496 seconds across a two-second sample; it resumed and completed after
  respawn, retaining99,000 Coins with exactly four gameplay requests.
- Native UI adversarial pass: all29 nodes in available/locked/completed/active
  states,17 inert placeholders, zoom0.75–1.5 and minimize/reopen drafts. Four
  viewport sizes passed44-pixel targets, complete inventory tiles and scrolling
  custom-army cards. All13 civilizations' ten held-building preview/count tiles
  rendered without changing preview sources. Native textbox focus suppressed
  hotbar input;1 button/B,2 and3 passed. No gameplay mutation remote was sent.
- Hidden UI guards: changed claim, read-only progress, reclaimed building and
  out-of-range deploy context invalidated correctly. Actual commander death
  cleared a minimized editor and a minimized chooser; old drafts remained inert
  after respawn.
- Real RemoteEvent round trips rejected12 malformed, locked, distant, stale and
  foreign-session intents. A buy request with forged price0/balance/owner data
  charged the authoritative250 Coins, exact replay charged nothing, and changing
  the operation under the same request ID was refused.

- Native researched combat/pose matrix:52/52 cases across13 civilizations × 4 roles
  passed, including extended melee/ranged/healing reach, maximum researched
  profiles, current-life health/timer preservation and replacements. Default
  original adapters created real Instance identities, not engine doubles.
  Native pose reconstruction checked1,591 parts; source templates stayed unchanged.
  Research completion, wounds, positions and simulation clocks here are explicit
  isolated fixture data, not live player/session changes.
- Seven stress cases passed:104 baseline/full-research role combinations,
  52 valid saved-settlement/capacity combinations at10/12/15/20 slots,22 malformed
  sync/command probes, waiting-group backfill/reclaim/Army 1 reset,1,248 bounded
  pose packets, and research through real simulated casualties/replacements.
- Eight full armies using the actual OriginalBehavior adapter completed600 steps
  across30 simulated seconds:184 peak actors,300 shots,363 hits,73 deaths,
  80 bandages and50 peak events per step. This standalone engine-double workload
  took64.2 seconds of wall time; it is not a native server FPS measurement.
- Native client ragdolls passed falling/limb physics, rider/animal articulation,
  fading/TTL, exact-life independence, source-folder replacement cleanup and
  reclaim-without-corpse. Observed limits stayed within12 models,1,200 parts and
  8 supports; the part-budget fixture peaked at1,125 parts and evicted oldest
  corpses as intended.

## Final repeats and verification boundaries

The final development gate passes34 OpenSpec items,9 Node cases,405 syntax files,
244 original logic cases and225 miniature logic cases, plus the immutable mount
asset audit. Pinned Selene and StyLua checks pass for the new files.

The native lifecycle/GUI/network fixtures were strengthened during review:
wait for actual button readiness, distinguish three/four requests depending on
initial selection, assert minimized panels are logically closed after death,
release input/flags on failure, count actual gameplay receipts, use unique
network request IDs and compare protected civilization state after refusals.
One operator death-handshake timeout was corrected in the test orchestration.
Final native repeats passed; death samples retained24.1001972 seconds unchanged,
then completed with99,000 Coins and no extra charge. UI tests measured zero
actual gameplay receipts while using isolated presentation copies.

Physical phones/controllers, physical multi-client play and published/real-store
restoration remain separate checks. The prior profile-close/reconnect retry
concern is still recorded in the implementation note; fake-store session fault
checks do not establish that real PlayerAdded/PlayerRemoving interleaving.
Existing imported asset type/approval warnings remain visible in Studio.

Raw native result records are saved locally under
`.cache/military-thorough-native-first-pass.json` and the tightened repeats in
`.cache/military-thorough-native-final.json`; repeatable fixture sources
live under `tests/miniature-game/Military*.luau`. The research test project maps
the new native fixtures; ordinary and funded player builds do not autorun them.

Generate with `npm run build:miniature-game-tests -- --research` and build
`.cache/miniature-game-research-test.project.json`. The current native artifact
is `build/clash-of-civilizations-thorough-tests.rbxlx`. In the isolated Studio
test contexts, `ServerStorage.NativeMilitaryMatrix` runs on Server; the
`ReplicatedStorage.NativeMilitaryLifecycle`, `NativeMilitaryUIGuards` and
`NativeMilitaryRemoteGuards` module functions run on Client. Lifecycle/death
fixtures raise explicit readiness attributes for the supervising test harness;
only the test commander is killed. The final repeat used a temporary Studio-only
death handshake installed by the supervisor, which vanished when Play stopped.

Owned verification Play sessions/windows were closed after evidence collection.
The user's original Play session was left running.
