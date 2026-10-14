# Design

## Context

See proposal.md for motivation. The current code only prints startup messages.
Rojo maps server, client, and shared folders; it leaves Workspace to Studio.
The user has verified both bootstrap scripts in a live Studio playtest.

## Goals / Non-Goals

**Goals:** Keep claim decisions deterministic and testable separately from the
engine, keep map generation confined to a runtime model, and make server results
visible in a small selection interface.

**Non-Goals:** Persistent profiles, teleports, formation/combat systems, and final art.
This slice must not introduce temporary save code that could overwrite future data.

## Decisions

1. A shared catalog exposes stable `sparta` and `britain` identifiers, labels,
   reference periods, and colors. This is prototype content, not the full roster.
2. A server-only claim registry owns civilization-to-player and player-to-plot
   assignments. Its claim operation never yields, so checking and reserving a
   civilization/plot happens in one server execution segment. Repeated requests
   for the same claim are idempotent; changing civilizations requires leaving.
   Client-side assignment was rejected because it cannot guarantee exclusivity.
3. A small server controller handles actual Players, a RemoteFunction for
   initial state/selection, a RemoteEvent for availability updates, and a
   per-player request cooldown. Player identity comes from the engine callback,
   not client arguments. Snapshot results are copied and contain no mutable registry state.
4. A map module creates `Workspace.CivilizationPrototype`: entry spawn, central
   arena, radial paths, and eight numbered plots. Claim updates change labels,
   accents, and simple settlement blocks. It never clears unrelated Workspace objects.
5. A client UI module uses native TextButtons with Activated, explicit pending
   and error states, bounded request waiting, live availability, and a confirmed
   settlement HUD. Standard Roblox controls remain available. Initial layout is
   a dark neutral panel with gold accents and a vertical list sized for small screens.
6. CharacterAdded handlers place owners back at their plots after respawn;
   unclaimed players enter at the lobby. Departure clears attributes, cooldown,
   registry ownership, and visible plot ownership before broadcasting availability.

## Risks / Trade-offs

- Only two selectable civilizations → Label the slice as a two-civilization,
  session-only prototype, with the other six plots visibly unclaimed.
- A selection response can race an availability update → Derive confirmed
  personal ownership from server-assigned player attributes; server state wins.
- RemoteFunction calls can stall → Use a client timeout with safe retry and do
  not predict ownership. Late results must not overwrite a newer UI request.
- Generated map appears during Play → Explain this in the playtest guide.
- A larger or customized existing map might overlap the prototype → Keep map
  coordinates grouped and configurable; do not delete developer-created geometry.
- Direct Studio access may be unavailable → Run engine tests through the
  official local-file script runner where possible and explicitly record any
  remaining live-client or multiplayer verification rather than declaring it passed.

## Migration Plan

Sync modules through the existing Rojo connection, stop/start Play, then verify
selection in a single client and conflicting claims with multiple Studio clients.
Reverting this change restores the connectivity-only scripts. No save migration
or published-server deployment is involved.

## Sources

- [Remote communication and server authority](https://create.roblox.com/docs/scripting/events/remote)
- [Native button activation](https://create.roblox.com/docs/reference/engine/classes/GuiButton)
- [Studio local script execution](https://create.roblox.com/docs/studio/command-line-interface)
