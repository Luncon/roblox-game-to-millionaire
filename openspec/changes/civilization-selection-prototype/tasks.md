# Tasks

## 1. Claim rules

- [x] 1.1 Add a Studio-executable claim test harness and confirm it fails before the registry exists.
- [x] 1.2 Implement the shared catalog and server-only registry; pass tests for conflicts, invalid input, capacity, idempotency, release, and isolated snapshots.

## 2. Battlefield and player lifecycle

- [x] 2.1 Generate the eight-plot runtime map and ownership visuals; pass engine tests for layout, updates, release, and unrelated Workspace preservation.
- [x] 2.2 Wire server-owned remotes, throttling, player attributes, respawns, and departure cleanup; verify a successful and rejected selection with live server/client requests.

## 3. Selection interface

- [x] 3.1 Implement the responsive Sparta/Britain selection interface and claimed HUD; verify pending, unavailable, retry, success, and respawn states in a Studio client.
- [x] 3.2 Document the playtest steps and current prototype limits; verify local documentation links and the documented test-project build commands.

## 4. Integration verification

- [x] 4.1 Pass strict OpenSpec validation, engine tests, and the production Rojo build; record the commands and results.
- [ ] 4.2 Verify duplicate selection and release with multiple Studio clients, and check narrow-screen and alternate-input behavior; record any outstanding runtime checks explicitly.

Multiplayer conflict/release and a 319-pixel-wide phone viewport passed. Physical
touch/controller activation remains unverified: simulated ButtonA input did not
activate a button. Keep 4.2 open until that interaction is demonstrated.

## Workflow follow-up

- Archive only after tracked implementation and verification tasks are complete.
