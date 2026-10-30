# Design

## Context

See proposal.md for scope. Miniature gameplay already has per-civilization validated fake-store progress, active production clocks, authoritative requests and stable building-owned troop lives. Its old nine-node research remains paused and must not re-lock shops. Original shared encounter and medical helpers use fixed reach defaults.

## Goals / Non-Goals

Implement the user's military table and army-control references without changing legacy full-size combat, opening real storage or resetting existing miniature progress. Main promotion changes the development entry point; publishing and production profile migration remain separate work.

## Decisions

- Preserve `default.project.json` as `legacy-fullscale.project.json`, then copy ordinary `miniature-playtest.project.json` into default with the main name/default port. Keep preview/funded variants and backups distinct. Existing full-size test generation reads the legacy mapping.
- A shared immutable military catalog owns IDs, reference rows, prerequisite graph, cost/time, effect and hex coordinates. Server projects save `{completed,project?={id,remaining}}` as `militaryResearch`; the paused older `research` field is retained. One project advances on the existing living, selected, writable active clock; wall-clock/offline deadlines would violate current inactive-time rules.
- Additive tier totals are foot/mount damage and HP +40%; foot speed/reach +35%; mount speed/reach +30%. Weighted capacity adds 2/3/5 to ten. Derive immutable per-army profiles; update max health without adding health, retaining contacts, cooldowns and pending respawns.
- Optional reach hooks in original encounter/tactics/medical helpers default to unchanged original values. Preserve the actual original miniature melee reach of 1.25 studs (original five at quarter scale), scaling it proportionally; do not silently substitute nominal 2.5. Ranged/heal baselines remain ten/seven. Existing shots keep launch reach.
- Persist fixed `army2/army3/army4` arrays of building IDs with strict dense, disjoint, owned military membership; missing-only defaults and malformed-data rejection. Army 1 is derived all-buildings. Configuration mutates presets only. CombatController keeps transient per-building targets, including waiting-capacity structures, and supplies them to Battle; Army 1 clears overrides.
- Keep existing request session/epoch/revision/replay/write/life guards. Research start and portable group editing validate selected ownership; outpost deploy additionally rechecks proximity. Only the server computes costs, completion, stats and troop/group membership.
- Native hex tiles use rotated Frames with fixed graph coordinates, prerequisite connectors, pan/zoom and responsive details. Civilian half and excluded modern nodes remain inert grey placeholders. Inventory uses existing viewport previews and grid counts. Army edit/deploy UI keeps drafts local and checks life/civilization/range while hidden.

## Risks / Trade-offs

- Long reference prices/timers make later tiers difficult to test normally → deterministic clock fixtures and an explicit separate native research fixture; do not alter ordinary or funded review seeds.
- Shared original combat helpers risk legacy regressions → optional default-preserving hooks, all original logic regressions plus effective-range tests.
- Project switching can leave old bootstraps in existing Studio places → build/open a fresh main place for verification; preserve the user's active playtest and avoid syncing mismatched legacy places.
- Fake-store progress remains temporary → document this boundary and retain Studio-only bootstrap guards.

## Migration Plan

Validate old progress before adding missing fields, reject malformed partial fields, and preserve all previous records on load failure. Keep the legacy mapping and dated backups for rollback. Run offline gates, fresh Rojo builds and one isolated Studio verification alongside the user's playtest. Record exact native evidence and any remaining client limitations in the vault.
