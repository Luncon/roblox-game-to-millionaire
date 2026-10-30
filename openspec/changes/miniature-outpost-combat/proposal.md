# Proposal

## Why

The miniature economy and military buildings work, but their troops are passive.
Players need a first combat objective: defeat and occupy a nearby neutral outpost,
raise their civilization flag, then defend it against another player's army.

## What Changes

- Add one capturable outpost on each of the eight home-to-center lines, initially
  defended by two neutral melee fighters and one ranged fighter.
- Give building-owned troops server-controlled movement, melee/ranged combat,
  replenishment and medic support under the existing total army cap of ten.
- Automatically target the next uncaptured outpost on the army's own line. The
  initial playable line contains one outpost; deeper, harder tiers remain later work.
- Let a living owner press E at any outpost center to retarget their entire army.
- Require all defending troops to be defeated and attackers to occupy the outpost
  for twenty clear seconds. Returning neutral defenders or a rival force pause
  progress; no attackers resets it. Display progress and fly the victor's flag.
- Keep player homes, commanders and civilians outside conquest/combat targets.

Confirmed: NPC respawns pause capture,20seconds, neutral2/1, rival recapture,
automatic line targeting, E override, protected homes and fixed10army capacity.
Prototype choices: neutral respawners stop on capture; existing armies defend
captured ground without free extra garrisons; ownership resets with this fake-store
server and neutralizes when its army's civilization/claim is released.

## Capabilities

### New Capabilities

- `miniature-army-combat`: bounded server simulation of building-owned troops,
  movement, strikes/shots, medics, deaths and respawns with fresh authority.
- `miniature-outpost-conquest`: outpost geometry, army objectives, validated E
  targeting, neutral defenders, timed capture, flags and rival recapture.

### Modified Capabilities

None. The main specification currently contains development-workflow only.
The earlier miniature economy/art change remains independently reviewable;
its passive-troop boundary is superseded only by this separate combat capability.

## Impact

Add isolated simulation, rendering and client prompt modules under
`prototypes/miniature/game`; integrate Runtime's existing guarded transport and
building group allocation. Add fake-store logic/native checks and vault evidence.
No dependencies, production service bootstrap, real save fields, rewards,
research, player weapons, protected-home raids or published release are included.
