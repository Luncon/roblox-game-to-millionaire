# Design

## Context

The isolated sandbox has13quarter-scale culture kits,80×64plots on a400-stud
ring, automatic2/2/1building groups under10total, injected fake storage and guarded
RemoteEvent intents. World periodically places passive figures beside buildings.
The production combat services depend on full-scale arenas/profile progression;
loading those into this sandbox would cross the isolation boundary.

## Goals / Non-Goals

**Goals:** keep server combat independently testable, give each actor exactly one
runtime owner, make capture rules visible and preserve the working economy/input.

**Non-Goals:** profile migration, production combat integration, real stores,
player weapons/damage, conquest income, free captured garrisons, research or deeper
map tiers. No replacement of original meshes, joints, clothing or grip sources.

## Decisions

1. Use a pure numeric x/z battle simulation with bounded substeps and a separate
   Roblox renderer. This makes windup/contact, life IDs, respawn deadlines,
   contested occupation and authority loss deterministic. Humanoid AI/pathfinding
   is unnecessary for anchored miniature models on the flat prototype map.
2. Derive stable army slot IDs from owner/civilization/plot/building/index. Reconcile
   current groups without reviving or repositioning unrelated lives. Commander
   respawn invalidates command intents but retains the same owned army. Claim
   release, civilization switch or write-authority loss removes that army.
3. A Runtime controller marks managed plots so legacy World figure synchronization
   cannot overwrite combat movement. Dedicated BattleActors clone the immutable
   previews. Civilians keep their existing worker renderer and remain noncombatants.
4. Place outposts110studs inward from their plot center: radius290fromhub, radius22
   occupation zones clear of the160×128home reserves and neighbors. One node per
   line is delivered; nextId supports later progression and is tested with synthetic
   two-node lines rather than claiming additional native settlements exist.
5. Neutral slots respawn while neutral. Pausing the bar for live defenders, as
   confirmed by the user, gives20clear occupied seconds across defended waves.
   Losing the attackers resets it. Capture cancels neutral deadlines. Existing
   armies, rather than free extra garrisons, defend player-owned ground.
6. Route E through the existing session/epoch/revision/rate/life/range gateway.
   The client sends only outpostId; application of the transient command occurs
   after successful state validation. Fresh server authority is reconciled before
   each simulation tick. No damage, health or capture progress remote exists.
7. Store no combat fields. Fake economy saves retain their schema; flags, health,
   timers and orders reset with the server. Leave production, clean preview,
   dated backup and the user's current Play untouched.

## Risks / Trade-offs

- Flat movement does not navigate future solid fortifications → keep this first
  outpost's scenery nonblocking; defer complex terrain/pathfinding to its own work.
- Numerous anchored models and networked pivots can cost frame time → cap armies,
  bound effects and ticks, measure the native fixture and report its scope.
- Balance may need iteration → centralize test defaults; retain actual20s capture
  and distinguish any funded test bootstrap from ordinary200Coins.
- A solo fixture does not establish published multiplayer or phone/controller
  performance → test rival simulation deterministically and in an isolated native
  fixture, and state the remaining physical/published checks explicitly.

## Verification and rollback

Use pure fake-store cases for contacts, shots, medics, exactly20s capture, pause,
reset, replay, authority loss, recapture, replacements and multi-node progression.
Run native ordinary/funded UI placement, movement/combat, defender respawns,
overhead bar/flag and E retargeting. Record source fingerprints and isolation.
Keep at most the user's Play and one owned verification Play, closing the latter.
Build a distinct ordinary combat review file; reverting this separate mapping's
combat integration restores the prior passive sandbox without production changes.

Roblox's [client/server boundary guidance](https://create.roblox.com/docs/scripting/security/client-server-boundary)
requires independent server checks for client-triggered prompts. The existing
guarded gateway is retained rather than trusting prompt visibility or distance.
