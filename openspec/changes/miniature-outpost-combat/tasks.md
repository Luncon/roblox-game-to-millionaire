# Tasks

## 1. Server battle and occupation rules

- [x] 1.1 Implement deterministic building-owned army slots, movement, validated melee/ranged contacts, medic support and life-specific respawns under ten total; verify authority/slot reconciliation and attack/heal invariants with miniature logic cases and document test defaults in the combat vault note.
- [x] 1.2 Implement neutral2melee/1ranged respawns,20clear-second capture with pause/reset/contest, owner flag state, rival recapture, automatic next-node progression and manual objectives; verify deterministic timing, recapture and synthetic two-node scenarios and record current one-node scope.

## 2. Native world and guarded interaction

- [x] 2.1 Add eight correctly placed neutral outposts, civilization flags, overhead progress, inert per-life combat visuals/health bars and bounded ranged effects; verify native bounds, source immutability, actor lifecycle and display state in an isolated server fixture and document evidence.
- [x] 2.2 Integrate fresh writable-army reconciliation and the existing life/range/session/revision/replay gateway, isolate combat rendering from worker/legacy figure synchronization, and add E targeting without management pages; verify invalid/stale/distant orders, protected homes and unchanged economy schema with logic/native checks and update controls.

## 3. Integrated playtest and handoff

- [x] 3.1 Run the funded fake-store native UI flow through military purchase/placement, automatic march, attacks, neutral respawns, paused/resumed capture, flag completion and real E retargeting; record funding, actual timing and any explicit limits, plus separate simulated rival recapture evidence.
- [x] 3.2 Pass development gates, inspect native console/performance scope, preserve production/preview/backup and user Play, close owned verification windows, rebuild the ordinary combat sandbox and update the vault launch/evidence links for review.

## Workflow follow-up

- Review the recorded behavior before archiving. Published multi-client play,
  physical phone/controller performance, real storage, deeper objectives,
  difficulty progression and conquest income remain separate work.
