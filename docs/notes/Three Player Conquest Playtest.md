# Three Player Conquest Playtest

Status: **PARTIAL RESULT** — three real clients captured their neutral outposts;
the later Roman takeover assertion timed out. The complete scripted acceptance
run did not pass.

The user requested three actual clients playing and capturing simultaneously.
This requires a single isolated Studio multiplayer verification run with three
clients; the existing user playtest remains separate. The test uses the miniature
game's ordinary server/client modules and original assets, with one dedicated
Studio-only bootstrap. Only this fixture seeds **20,000 Coins per civilization**
through the injected FakeProfileStore. It does not open real player storage or
change the ordinary 200-Coin startup.

Generate the mapping with `npm run build:miniature-multiplayer-tests`. It writes
the ignored `.cache/miniature-three-player.project.json`, named
`ClashOfCivilizationsThreePlayerTest`, on Rojo port **34876**. Build that mapping
into a separate place. The generator keeps exactly one game Main client and adds
one guarded ThreePlayerBot; it replaces the ordinary Bootstrap through explicit
Sandbox children. ThreePlayerCoordinator is the separate server test script,
and ThreePlayerContext is its server-only coordination module. Earlier solo
native autorunners and legacy full-size services are excluded.

The orchestrator will start the owned test from Edit using
`ExecuteMultiplayerTestAsync(3, {suite='miniature-three-player', timeout=600})`.
The coordinator will end the test through the Studio test service. These are
planned orchestration steps, not proof that a run has completed. Client fixture
startup requires Studio and the `MiniatureThreePlayerFixture` marker; the ordinary
Runtime additionally requires the injected fake store. The clients retain the
game-owned input controller.

For a visible Windows run, use
`npm run build:miniature-multiplayer-visible` (or pass `--visible` to the generator).
This writes `.cache/miniature-three-player-visible.project.json`, named
`ClashOfCivilizationsThreePlayerVisibleTest`, on port **34877**. Build it to a
separate place, for example:

```text
rojo build .cache/miniature-three-player-visible.project.json --output build/miniature-three-player-visible.rbxlx
```

Open that built place in Studio. In **Test → Server & Clients**, select **3
players**, then press **F7** to launch the visible server and clients. The build
stores `VisibleRun=true` on the `ThreePlayerCoordinator` Script in
ServerScriptService. F7 loads the on-disk place: changing an unsaved Edit attribute
does not enable this mode. A DataModel attribute did not survive the observed
save/F7 launch, so the reproducible build uses the Script attribute instead. The
ordinary test mapping and default main build do not receive the visible flag.

The coordinator drives the three bots while their normal HUDs, armies and world
remain visible. Watch the replicated `MiniatureThreePlayerTest.Phase` attribute
and its `Result` StringValue, or the DataModel's `MiniatureThreePlayerPhase` and
`MiniatureThreePlayerResult` attributes. After completion or failure the bots stop
and the visible world stays open for inspection; Studio's **Stop** control ends
the run. The normal Walk/Overview, Buy/Civilization/Sell and inventory controls
remain game controls, but intervening while bots are active can invalidate the
scripted acceptance sequence. A visible launch is still not a capture result.

The run should record distinct players, exclusive claims, paid construction,
simultaneous autonomous armies, defended outposts and capture ownership. Evidence
must separate real client actions from declared funding and server observation.
Any failed assertion, timeout, client error or unfinished capture remains visible
in the result. A generated mapping, Node regression or Rojo build alone does not
establish multiplayer gameplay.

The focused mapping regression,
`node --test scripts/tests/miniature-multiplayer.test.mjs`, passed its initial two cases on
October 29, 2026. It checked every mapped dependency after the fixture files
landed, retained assets and fake-store isolation, one Bootstrap/Main/bot, excluded
old autorunners, and unchanged ordinary project mappings. The complete development
suite was not repeated for these tooling-only changes.

The orchestrator's separate native connectivity probe successfully started three
actual Studio clients with distinct UserIds **−1, −2 and −3**. Each had the normal
Main HUD and a writable development profile. That probe established multiplayer
startup and connectivity only; the subsequent partial conquest run is described
below. No conquest pass is inferred from the probe. The existing user playtest
was not modified by this tooling work.

The subsequent visible run used three real clients, normal guarded client
RemoteEvents and scripted Humanoid movement (rather than GUI input). Sparta
captured **outpost_1**, Rome **outpost_3**, and Egypt **outpost_2**; each captured
site had zero remaining neutral defenders. Paid construction, concurrent armies
and defended/paused capture progress were observed. The coordinator did not
observe its contested-state condition. Its later phase, “third client retargets
home; Rome must take Spartan outpost”, failed the Roman takeover/physical-flag
assertion at **313.268 seconds**. No enemy takeover or complete balance pass is
claimed. The structured local result is
[miniature-three-player-visible-result.json](../../.cache/miniature-three-player-visible-result.json).
Profiles in this run remained temporary fake-store records with declared funding.

[Military testing](Military%20Research%20Thorough%20Test%20Pass.md) ·
[Main build and army controls](Military%20Research%20and%20Army%20Control.md) ·
[Gameplay sandbox](../MINIATURE_GAMEPLAY.md)
