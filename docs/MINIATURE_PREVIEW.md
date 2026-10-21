# Miniature scale preview

Build `miniature.project.json` with Rojo to `build/miniature-preview.rbxlx`, then
open that file in a separate Roblox Studio window and press Play. Keep the main
Clash of Civilizations place open separately if desired; use at most two playtests.

This first scene is Sparta at quarter scale: a house, grain farm and barracks,
four equipped patrolling soldiers and two tending workers. Your avatar keeps its
normal size. Scene buildings and actors are nonblocking. No profile store,
production economy or player combat scripts are mapped into this project.

The preview runs only in Studio. It is a scale/movement sample; purchases,
placement, resource production/selling, research, combat and conquest follow in
later slices. The shared Black Market is deferred. Existing production behavior
and the [pre-redesign checkpoint](BACKUPS.md) remain available.

Scale, route speed and descriptions live in
`prototypes/miniature/shared/Config.luau`. Reused models are sanitized clones;
changing preview scale does not edit the original assets.

Select a building with a mouse/touch click or use its nearby Inspect prompt (E
on PC). The information panel shows the building's intended purpose; its minus
button preserves the information for restoration. Walk follows your avatar;
Overview frames the plot and supports wheel/trackpad zoom or touch pinch.
Respawning restores Walk. These controls have no purchase or combat actions.

## Native verification

Run `npm run build:miniature-tests`, build `.cache/miniature-test.project.json`
with Rojo, and open the resulting isolated test file. Before Play, record the
source-template fingerprint in Edit:

```lua
game.ReplicatedStorage:SetAttribute("OriginalTemplates",
    require(game.ServerStorage.TemplateFingerprint)())
```

After Play, focus Client and run:

```lua
return require(game.ReplicatedStorage.NativeInputChecks)()
```

Keep the viewport on Client during input. Read `MiniatureSceneResult` and
`MiniatureInputResult` attributes on ReplicatedStorage from Client. The fixture
tests world clicks, E input, overview zoom, movement through the house footprint,
respawn/camera recovery and four bounded layouts. Its respawn remote exists only
in the generated test project; the regular preview contains no test scripts.
The input fixture initializes Roblox's ordinary PlayerModule controls in the
Studio tool's execution context before virtual keyboard events. Production
preview scripts do not replace, enable or disable those movement controls.

Native input verification passed three world clicks, the farm E prompt,
minimize/restore/close, Walk/Overview and wheel zoom, commander movement through
the house footprint, normal-size unarmed respawn and recovered camera tracking.
The real UI module also fitted 320×360, 320×568, 640×360 and 1024×768 bounded
frames. These checks do not establish physical phone/controller behavior or
published multiplayer gameplay. Studio also logged an asset-type warning for
`203785492`; its source was not narrowed down, and no source asset was edited.

Final integration passed both scene and input fixtures in one uninterrupted
native Play session. All 255 Luau files compiled; strict OpenSpec validation
passed 27 items. Review covered scaled joints, collision groups, input/camera
lifetime, original-template geometry, profile isolation and bounded work.
Inverting the overview render gate only in the owned test place caused the
native wheel-zoom assertion to fail. Restoring the gate recovered the passing
input suite. Repository source was not mutated for that experiment.

The native scene fixture passed a 22-second observation covering complete patrol
and worker cycles: three quarter-scale buildings, six moving actors, normal
avatar size, equipped soldiers, ground/route bounds, and unchanged template
geometry. Miniature actor collision groups exclude the commander even when the
Humanoid engine re-enables torso collision. No profile or combat service is loaded.
