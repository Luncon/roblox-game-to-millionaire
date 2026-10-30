# Miniature services verification

2026-10-29. Separate **pre-unlocked, fake-only effects fixture**. This does not
replace the ordinary starter or prove research-duration pacing. See
[[Miniature Economy Implementation]] and [[2026-10-29-miniature-implementation]].

Run `npm run build:miniature-game-tests -- --services`, then build the generated
`.cache/miniature-game-services-test.project.json` with Rojo. It replaces the
normal bootstrap with `tests/miniature-game/ServicesBootstrap.server.luau` and
maps `Services.luau` as `ReplicatedStorage.NativeServicesChecks`. Verify exactly
one `ServerScriptService.Sandbox.Bootstrap` before Play. Start one isolated Studio
Play and call `require(game.ReplicatedStorage.NativeServicesChecks)()` in the
Client. Load a fresh ModuleScript instance or restart Play after source edits
because Roblox caches `require` results.

Every joining player's fake Spartan state receives 5,000 Coins, 80 Timber,
20 Material, an upgraded hall and all nine completed research nodes. Eligible
current-cycle stock is part of this declared setup. No clock override is used.
The compact starter has civic `(-6,-10,90)`, house `(-16,6,0)` and farm `(6,-10,0)`.
A local Lune probe validated that starter and the four subsequent paid placements
with actual State/Actions validation: Timber `(6,6,0)`, Storehouse `(-6,6,90)`,
Training `(-14,-10,90)` and Healer `(-16,12,0)`.

The client fixture uses actual UI buttons, native text input and server receipts.
Commander relocation and TextBox selection are explicit fixture setup. It covers
paid placement, a 25-Coin worker, real nine-second Timber production/collection,
the Storehouse's displayed 400-unit capacity, a 3 melee/1 ranged/1 medic passive
roster independent of workers, assignment presets, Porter collection, native
reserve entry and Trade Steward sales. It temporarily unassigns producers through
UI so exact collection/sale conservation is measurable, then restores the preset.
Manual selling runs while both services are enabled, and manual collection
controls remain available. Toggles finish off.

`MiniatureServicesResult` records receipts and partial evidence if a check fails.
Static StyLua/Selene checks pass. The native run passed on October 29: 400 capacity,
9.65-second Timber, retained workers with 3/1/1 figures, preset restoration, twelve
food collected/two sold above reserve 10 for four Coins, and manual controls while
services were enabled. One stale-revision placement was refused before a fresh
explicit retry; no duplicate charge occurred. See the [exact receipts](../assets/miniature-services-native-2026-10-29.json). The 400
capacity assertion in that first run checked accepted placement plus UI.

The final clean capacity run on October 29 used **one Bootstrap**, passed
isolation and reported no first-party script errors. Before Play, the services
test place had the Boolean `ReplicatedStorage.NativeCapacityFixture` attribute
set to `true` in Studio Edit mode. This explicit fake setup instead seeded
**200 Timber, zero Material/Clay and 60 farm output**, with the same 5,000 Coins,
improved hall and all nine completed nodes. Initial collected inventory was
exactly 200; the farm buffer was setup, not earned production.

Paid Storehouse, Training and Healer plans consumed 60 Timber. The newly assigned
worker produced one Timber after 9.52 real seconds, which manual collection
transferred. Porter then collected all **60 Food**, reaching **201 collected
goods within the purchased 400 capacity** before Trade was enabled. Trade sold
**50 Food above reserve 10 for 100 Coins**; protected Timber and zero Clay were
preserved. Manual controls, the passive 3/1/1 roster, retained workforce and
presets also passed. Read `inventoryAfterPorters`, `seededGoods`, `capacityFixture`
and receipts in the [clean capacity evidence](../assets/miniature-capacity-native-2026-10-29.json).
Absent or false, the attribute preserves ordinary services funding of 80 Timber
and 20 Material/Clay; neither funded mode changes the normal 200-Coin starter.

These fixtures establish no new research completions, combat/healing, live
storage, published multiplayer or physical-device acceptance. The bootstrap
remains Studio-only.
