# Military Research Rules

October 29, 2026. This records the implemented rules for the miniature main
development build. Native UI and gameplay verification is recorded separately;
the deterministic checks below do not establish published multiplayer or storage.

The [user's Mini Wars reference](Mini%20Wars%20References.md) supplies the prices,
durations and prerequisite paths. The immutable
[MilitaryResearch catalog](../../prototypes/miniature/game/shared/MilitaryResearch.luau)
is the current executable list of 29 nodes, their stable IDs, adopted names,
reference row numbers, edges and hex coordinates. Vehicle bonuses become mounted
bonuses. Mech Station, Spider Base, Air Fortress, both rocket-limit tiers and both
rocket-cooldown tiers remain unavailable. Civilian research remains a future half
of the tree. These projects do not gate building purchases or resume the older
nine-node economy/service research.

Research costs Coins once when the server accepts an eligible project. There is
one project per civilization, with no hall upgrade required. Its remaining active
seconds save with that civilization. Only selected, living, writable play advances
it. Switching, death, disconnection and lost authority pause progress; offline
time does not complete it. A new project cannot use unused elapsed time from a
previous project. An invalid, busy, completed, locked or unaffordable request does
not charge. The first project, Army Training, costs 1,000 Coins and takes 30 active
seconds; the reference's later prices and long timers are retained for initial
tuning.

Completed tiers add percentages to the original role baseline. They do not
multiply each other, and a mount receives only mounted bonuses. Foot includes
melee, ranged and medics: medic health, speed and healing coverage improve,
while medics remain nonoffensive and their bandage amount/cadence stay unchanged.

| Branch | Tier additions | Full branch total |
| --- | --- | --- |
| Foot or mounted damage | 5%, 10%, 25% | 40% |
| Foot or mounted maximum health | 5%, 10%, 25% | 40% |
| Foot speed and reach | 5%, 10%, 20% | 35% |
| Mounted speed | 5%, 10%, 15% | 30% |
| Mounted reach | 10%, 20% | 30% |
| Weighted army capacity | 2, 3, 5 | 10 → 12 → 15 → 20 |
| Army Control groups | One group each tier | Army 1 plus up to three custom groups |

Capacity applies to the civilization's allocated building troops as a whole.
Custom groups select those troops; they do not duplicate them or add another
capacity pool. A rider still consumes two slots. Whole building groups that do
not fit wait and backfill when space becomes available. Group membership and
transient deployment targets are separate from research.

Health research raises maximum health without adding current HP. A wounded
troop remains wounded, and even a fully healthy troop retains its previous HP
when its maximum rises. Genuine medic healing can subsequently restore it.
Existing lives, pending contacts, attack/healing cooldowns and replacement
deadlines survive research synchronization. A newly spawned life starts at its
researched maximum. Current speed and damage use the derived researched profile;
already launched projectiles retain their original launch reach.

## Effective range and speed

The native adapter continues to run the original combat planners at quarter
scale. Its original melee contact baseline is **1.25 studs**: the original
five-stud contact multiplied by 0.25. The numeric Battle profile has a separate
nominal **2.5-stud ceiling**. Research scales both proportionally, and the tighter
original contact check remains authoritative; research does not silently double
the original melee baseline. This applies to mounted melee as well.

| Actual native behavior | Baseline | Full applicable branch |
| --- | --- | --- |
| Foot melee contact | 1.25 | 1.6875 studs |
| Mounted melee contact | 1.25 | 1.625 studs |
| Ranged reach | 10 | 13.5 studs |
| Medic healing coverage | 7 | 9.45 studs |
| Foot movement | 6 | 8.1 studs/second |
| Most mounted movement | 9 | 11.7 studs/second |
| Elephant/camel movement | 5.5 | 7.15 studs/second |

Optional per-actor reach hooks in the original encounter, target selection and
medical helpers allow these bonuses without mutating shared configurations or
copying planners. Callers that omit the hooks retain the original full-size
defaults. The ranged approach distances scale with reach, so improved reach can
affect actual firing positions. Medical launch and impact checks both use the
appropriate range and current troop life. Neutral defenders receive no player
research bonuses.

## Implementation contract and evidence

Each civilization saves `militaryResearch = { completed, project? }`, with the
project containing only `id` and `remaining`. Unknown nodes, broken prerequisite
chains and malformed projects fail validation. The older `research` record is
retained. The root integration adds missing fields only to otherwise valid old
records; failed loads must never replace existing progress.

Shared APIs are `new`, `validate`, `validateCompleted`, `modifiers`, `capacity`,
`groupSlots` and `profile`. The server module exposes `start(state, id)` and
`step(state, elapsed, active)`. `Battle.syncArmy` accepts the server-validated
completed set and optional canonical building targets; research changes do not
change the global baseline configuration. Per-army derived profiles are frozen
and reused while completed research is unchanged.

At this slice's freeze, `npm run check:miniature` passed **169 logic cases** plus
the imported mount audit, and `npm run check:skills` passed **244 legacy logic
cases**. The research tests cover payment, pauses, exact completion, graph/data
validation and additive effects. Combat tests exercise real original-helper
melee contact beyond 1.25, ranged release beyond 10 with delayed damage, medic
healing beyond 7, unchanged launched-shot reach, weighted capacity and independent
building targets, current-life health and pending replacement clocks. Changed
files passed pinned StyLua checking and Selene with zero diagnostics.

Studio physics, actual research/group input, fresh main builds, mobile input,
published multiplayer and durable storage are separate verification boundaries.
The development bootstrap still injects FakeProfileStore and rejects non-Studio
servers; this feature does not open legacy or live player DataStores.
