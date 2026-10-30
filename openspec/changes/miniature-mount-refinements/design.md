# Design

## Context

See proposal.md for the playtest corrections. Existing Battle actors own numeric health, movement and respawn clocks; OriginalBehavior bridges the original tactical helpers. OutpostWorld currently destroys dead visual sources immediately. The renderer poses anchored local clones and hides replicated source geometry. Animals use a joint graph over eleven immutable supplied templates.

## Goals / Non-Goals

**Goals:** visible requested model corrections, coherent anatomy and grounded riders, shared species speed in both server paths, and genuine cosmetic physical collapse on exact-life combat deaths.

**Non-Goals:** changing normal infantry movement, health/damage/capacity, importing animal controllers, creating a second combat authority, player ragdolls or saving corpse state.

## Decisions

1. Use immutable per-civilization mounted profiles shared by Battle and OriginalBehavior. Elephant and camel speed is 5.5, others 9; ordinary troop profiles remain unchanged. Configure elk overall length 2.9 (from 3.6) and bear 3.25 (from 3.5). This avoids global profile mutation or divergent adapters.
2. Adapt fresh animal clones only. Seat the lion rider against the visible back; replace slender bull lower-leg geometry with short rectangular limbs/hooves. Add two black eyes to wolf/rhino and simple block muzzle/nostrils to rhino. Rework crocodile hip pivots and mirrored yaw/roll to visibly sweep its splayed feet. Keep all thirteen original rider appearances and animal feet in the shared grounded hierarchy.
3. Process confirmed Battle death events before source cleanup. Publish one exact actor/life/time death notice on its retiring source, mark it dead, stop posing it, and retain the inert source briefly (about .35s). The renderer validates the notice against its current record, detaches the latest visible clone once and turns it into a physical corpse. Removal without the notice stays ordinary cleanup. This avoids interpreting reclaim or civilization switches as deaths and introduces no client gameplay request.
4. Articulate R6 neck/limbs and marked animal joints with limited BallSockets at their current pose. Preserve rigid gear/furniture via fresh welds; retain only disabled clothing Humanoids. Bound collision proxies rather than enabling collision on every decorative mesh. Dead bodies are presentation only, absent from Battle and capture immediately, with unchanged respawn deadlines.
5. Register corpse/ground collision groups on the server. Apply the ground group only to sandbox physical ground/plot slabs. Corpse proxies collide with these slabs and not default characters, living actors or other corpses; visible geometry remains nonqueryable/noncolliding. Verify actual selection/ray exclusion natively, including the engine's CanQuery/CanCollide interaction.
6. Bound corpses to six seconds with a final fade, twelve models and a fixed total part budget. Evict oldest before exceeding a bound. Renderer/scene teardown cleans corpse models, attachments, constraints and listeners; retired source cleanup is independently bounded. Replacement lives never reuse corpse records.
7. The user's subsequent request removes both twelve-building and twelve-held-plan ceilings. Validate dense building arrays and finite exact nonnegative per-kind item counts without an aggregate gameplay count cap. Retain spatial checks, unique civic/storehouse semantics, stock/currency guards, goods storage, troop capacity and canonical monotonic IDs; reject numeric overflow rather than introducing a replacement gameplay cap.

## Risks / Trade-offs

- Replication of removal before death metadata → briefly retain the marked source and consume the atomic notice independently of ChildRemoved; no corpse from missing/stale notices.
- Many-part crocodile or elaborate equipment → only anatomy articulates, decoration welds rigidly, and explicit model/part/collider limits cap cost.
- Explosive joints or floating seats → preserve current joint world frames, suppress self-collision, use gentle impulses, and test live physical settling plus all thirteen pose/appearance regressions.
- New collision groups changing commander movement → assign only owned sandbox support slabs and prove default movement/query behavior in Studio.
- Multiple open Studio plays → preserve the user's current all-civs Play; user approved stopping the two older sessions to make room for one isolated run.

## Migration Plan

No saved fields or template asset changes. Rebuild ordinary and all-civilization funded review places from filesystem sources; active Plays keep old code until restarted. Preserve user import workbench, source banks, production and clean preview. Record native evidence and remaining published/mobile/network limits in the shared Obsidian Markdown vault.
