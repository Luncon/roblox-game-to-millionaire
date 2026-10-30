# Development setup

## What is configured

- WSL already has Node.js 24.21.0 and npm 12.0.2. Version files pin the repository's reference runtime.
- OpenSpec 1.14.1 is a local development dependency with a committed lockfile.
- OpenSpec's six core Codex skills are installed under `.agents/skills/`.
- The repository is an Obsidian vault with Markdown links and note/attachment folders.
- Rojo's project mapping and minimal Luau startup scripts are ready for a connection check.

Node.js and the Obsidian desktop application are machine installations; their
project settings live here. Node dependencies are installed in ignored
`node_modules/`, not committed as application binaries.

## Node and OpenSpec in WSL

From the repository root:

```bash
nvm use
npm ci
npm run openspec -- --version
npm run check
```

On a different WSL machine with nvm already installed, run `nvm install` first.
The repo does not alter shell startup files or install a separate Windows Node runtime.

Useful commands:

```bash
npm run openspec -- list
npm run openspec -- list --specs
npm run openspec -- doctor
```

Open a new Codex session to discover the generated skills. In Codex CLI or IDE chat:

```text
$openspec-propose civilization-selection-prototype
```

Use plain language to describe the feature alongside that invocation. Review the
proposal before implementation. Use `$openspec-apply-change` to implement its
tasks and `$openspec-archive-change` once the work and relevant verification are complete.
In the desktop app, select the corresponding skill in the Skills sidebar.

`npm run check` validates specification structure. Studio playtests and published
Roblox client tests are separate evidence. See the [OpenSpec setup guide](https://openspec.dev/docs/setup).

Dependency installation scripts are disabled in `.npmrc`. See the
[dependency review](DEPENDENCY_REVIEW.md) for the current audit result and
historical upstream finding.

## Selene, StyLua, Lune and automated checks

From the repository root, using the pinned Node/npm installation:

```bash
npm ci
npm run setup:tools
npm run check:dev
```

`setup:tools` explicitly downloads official Selene **0.32.0**, StyLua **2.6.0**
and Lune **0.11.1** release archives, verifies their SHA-256 digests and installs
them under ignored `.cache/dev-tools/`. Versions, URLs and digests live in
[`dev-tools.lock.json`](../dev-tools.lock.json). No global installation, shell
startup change or npm installation hook is needed. The reviewed downloads cover
WSL/Linux x64 and Windows x64; WSL/Linux needs `unzip`, and Windows uses built-in
PowerShell extraction. Run setup separately in each environment. Other platforms
need reviewed release entries before the installer will accept them.

| Command | What it checks or changes |
| --- | --- |
| `npm run lint` | Selene on changed/new first-party Luau files |
| `npm run format:check` | StyLua formatting on those same files |
| `npm run format` | Formats those files, with StyLua AST verification |
| `npm run lint:all` | Full first-party lint scan |
| `npm run format:check:all` | Full first-party formatting scan |
| `npm test` | Tooling regressions, all-file Luau syntax compilation, then standalone logic cases |
| `npm run check:dev` | Strict OpenSpec validation, changed-file lint/format checks and `npm test` |

First-party scope is `src/`, `tests/`, `prototypes/miniature/` and `.lune/`.
Backups, imported assets, vendor skill examples and generated bundles are outside
that scope. Selene uses the committed `roblox.yml` API snapshot for offline,
repeatable Roblox globals; refresh it deliberately with the pinned Selene's
`generate-roblox-std` command. StyLua uses explicit Luau syntax and preserves
require order. Neither tool provides Roblox-aware type checking.

Local lint/format checks compare the worktree and index with `HEAD`, including
untracked files. To check committed branch changes in WSL, set
`LUAU_CHECK_BASE=origin/main` before the command. GitHub Actions compares against
the PR base or previous push SHA; a newly pushed branch uses its common ancestor
with the default branch, falling back to the last commit's parent when necessary
(an initial root commit checks all files). Missing comparison refs fail
the check. Any diagnostic or format drift in selected files fails the gate.

The initial full scan found 8,536 lint diagnostics and 250 files requiring
formatting. These remain visible through the full-scan commands; no rules are
disabled. Adoption checks changed files so tooling setup does not rewrite the
preserved production game. When editing an existing Luau file, its entire lint
and formatting check must pass.

Lune runs the existing explicit-engine-double suite: **244 logic cases** at setup.
The syntax smoke check compiles source without executing game bootstraps. Logic
fixtures use the injected FakeProfileStore; no player storage, Roblox credentials
or Studio window is used. Physics, rendering, UI input, teleports and native
replication still need the Studio/client checks documented below. GitHub Actions
runs these same offline checks on pushes and pull requests; it does not publish
the game. Node remains development tooling only.

### Project agent skills

Four skills from [afrxo/roblox-agent-skills](https://github.com/afrxo/roblox-agent-skills)
are installed locally: `luau-expert`, `roblox-dev`, `roblox-toolchain` and
`roblox-ui`. The core [Caveman skill](https://github.com/JuliusBrussee/caveman)
is also installed for optional concise replies. Invoke `$caveman` explicitly;
installation does not activate it. Its proxy, hooks, compression tools and other
skills are not installed.

These skills will be available on the next turn. The source revisions, licenses
and integration notes are recorded in
[the third-party skill record](../.agents/third-party/README.md). Repository
instructions and existing patterns take priority; verify skill API examples
against official documentation before using them.

## Obsidian on Windows

Obsidian is already installed on this machine. In its vault picker, choose
**Open folder as vault**, then select:

```text
C:\Users\smitl\Documents\GitHub\roblox-game-to-millionaire
```

Open `START_HERE.md`. New notes go to `docs/notes/`, attachments go to
`docs/assets/`, and links use standard Markdown. No community plugins are required.
Personal window/workspace state is ignored by Git; shared vault settings are tracked.
The notes and OpenSpec files are the actual repository files, not a synchronized copy.

### Everyday use

Start at [the vault home](../START_HERE.md), then follow the current-work links
or open [the project notes index](notes/INDEX.md). Use **Ctrl+O** to find an
existing note and **Ctrl+N** to create a note in `docs/notes/`. Give new notes a
descriptive title and add a relative Markdown link to the notes index. Record
ideas, decisions, references and playtest observations, including evidence and
unresolved questions where relevant.

Edit existing topic documentation when decisions change it. Keep approved
requirements in `openspec/changes/` and implemented behavior in
`openspec/specs/`; link to them rather than copying their contents into notes.
Obsidian saves the Markdown files locally; Git tracks those edits with the
rest of the project.

Reference: [Obsidian vaults](https://obsidian.md/help/vault).

## Rojo on Windows

The default project is now the miniature Clash of Civilizations game. Follow
[main gameplay instructions](MINIATURE_GAMEPLAY.md). The full-size game is preserved
in `legacy-fullscale.project.json`, and `miniature.project.json` remains the clean preview.

The user installed the Studio plugin and extracted Rojo 7.7.1 to:

```text
C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64
```

Use **Windows PowerShell**, rather than a WSL terminal, for the following commands.
The full executable path works without changing PATH:

```powershell
& "C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" --version
Set-Location "C:\Users\smitl\Documents\GitHub\roblox-game-to-millionaire"
& "C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" serve default.project.json
```

Keep PowerShell running. In Studio:

1. Open a new Baseplate place.
2. Open the Rojo plugin from the Plugins toolbar.
3. Connect to `localhost` on port `34872` (or the address printed by Rojo).
4. Review the sync preview, then accept the connection.
5. Press Play and open Output. Look for the civilization prototype's server and client startup messages.

`default.project.json` maps:

| Repository folder | Studio destination |
| --- | --- |
| `prototypes/miniature/game/server/` | `ServerScriptService/Sandbox` |
| `prototypes/miniature/game/client/` | `StarterPlayer/StarterPlayerScripts/MiniatureGame` |
| `prototypes/miniature/game/shared/` | `ReplicatedStorage/MiniatureGame` |

The mapping leaves Workspace and other services under Studio's control, so you
can build the map there. Edit mapped scripts in the repository; normal live sync
sends those edits into Studio. It does not automatically save Studio script edits
back into these files. Save your Studio place separately to preserve map edits.

An offline script build can be produced with:

```powershell
New-Item -ItemType Directory -Force build
& "C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" build default.project.json -o build\clash-of-civilizations-main.rbxlx
```

This build contains the mapped scripts; the Studio-built map is saved separately.
You do not need to run `rojo init` in this repository: the mapping already exists.

For reinstalling or another machine, use the official [Rojo releases](https://github.com/rojo-rbx/rojo/releases)
and [Studio plugin](https://create.roblox.com/store/asset/13916111004/Rojo).
The CLI can also install its matching plugin with `rojo plugin install` on Windows.
References: [installation](https://rojo.space/docs/v7/getting-started/installation/)
and [live sync](https://rojo.space/docs/v7/getting-started/new-game/).

## Runtime verification boundaries

Rojo builds verify that scripts map into a place file; they do not execute the
game. Check the connection and startup messages in Studio. Use a separate test
experience for persistent data. Test teleports in a published experience through
the Roblox application, since Studio play mode does not support them.

Keep at most two Studio playtests open at a time, allowing the user's playtest
and one isolated verification run together. Use solo Play for ordinary checks.
For automated checks isolated from player data, run
`npm run build:test-project -- --solo --development`, then build `.cache/solo-test.project.json`
with Rojo and open the resulting place in the existing Studio window. Press
**Play** normally; the solo harness uses an in-memory profile store and does not
launch extra clients. See [the playtest instructions](PLAYTEST.md#repeatable-engine-tests)
for build commands and structured progress/results.
Use multiple clients only when the specific behavior requires connected owners,
and close owned test windows before the next run.

References: [data stores](https://create.roblox.com/docs/cloud-services/data-stores)
and [teleports](https://create.roblox.com/docs/projects/teleport).

## Saved civilization profiles in the legacy full-size game

The default miniature game uses only temporary FakeProfileStore. The following
real-storage setup applies to `legacy-fullscale.project.json`, not main miniature
startup. Original full-size test generators explicitly use that legacy mapping.


The game saves each player's civilizations separately. In Studio, open **File →
Experience Settings → Security**, enable **Enable Studio Access to API Services**,
and click **Save**. The experience must be published for Studio storage access.
See [Roblox's setup instructions](https://create.roblox.com/docs/cloud-services/data-stores#enable-studio-access).

Studio uses `CivilizationProfilesV1` / `StudioDevelopment`; published servers use
the `Live` scope. Stop and restart Play after enabling access. The selector waits
for a safe profile load; an error does not create a replacement default profile.
Use the on-screen retry action after waiting, or rejoin if the progress session
has ended. [Profile behavior and schema](PROFILES.md) describes the guarantees.

`npm run build:test-project -- --solo --expansion` builds the economic expansion
check: Farm/Worker II, workshops, storage and Barracks V/VI. Use
`--solo --development` for the first building/army milestone; plain `--solo` retains the earlier world-growth
harness. Omitting `--solo` creates the separate multiplayer test
configuration. Both bootstraps inject an in-memory store. Automated regressions
do not access either real scope.
For a focused two-player persistence check, stop solo Play and use the generated
multiplayer test place. Run `tests/RunPersistenceMultiplayer.luau` through Studio's
Assistant MCP Edit context to check independent progress, switching, fresh Studio
sessions, failed loads and bounded retry traffic. Real Roblox storage restoration
is recorded separately in [the playtest log](PLAYTEST.md).

## Weapon skill checks and standalone Luau CLI

The optional Luau 0.740 command-line tools are installed on this Mac at
`~/.local/bin/luau`, `~/.local/bin/luau-compile`, and
`~/.local/bin/luau-analyze`, with the official release archive retained in
`~/.local/share/luau/0.740/`. They do not change the project's npm dependencies.
[Official Luau releases](https://github.com/luau-lang/luau/releases/tag/0.740)
provide binaries for other machines.

Run `npm run setup:tools` once, then `npm run check:skills` for deterministic logic tests, including skills,
economy, profile validation and fake-store restoration. The runner uses the
pinned project-local Lune install; `LUAU_CLI` can explicitly select the standalone
Luau CLI instead for compatibility with existing installations.
Explicit engine doubles support this CLI suite; physics, rigs and native input
require Studio. No player DataStores are opened.

`npm run build:test-project -- --solo --skills` prepares the dedicated fake-store
skill place. Build `.cache/solo-test.project.json` with Rojo, open the resulting
place in the existing Studio window, and run one solo Play session. See
[weapon skills](WEAPON_SKILLS.md) for the generated result attributes and the
[playtest record](PLAYTEST.md) for checks actually executed.

## Manual testing with 3,000 temporary coins

Generate a separate manual test place with the existing Studio-only in-memory
profile override:

```sh
npm run build:test-project -- --local-playtest
```

Build `.cache/local-playtest.project.json` with Rojo, then open that output place
in the existing Studio window and press Play. For the installed Windows tool:

```powershell
& "C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" build .cache\local-playtest.project.json -o build\local-playtest.rbxlx
```

Each civilization starts with **3,000 coins**; progress resets when Play stops.
The HUD labels the session as temporary. This generated project replaces the
production bootstrap with `tests/LocalPlaytest.server.luau`, injects only
FakeProfileStore and excludes automated test runners. Use `--local-playtest` by
itself. Normal `legacy-fullscale.project.json` startup and existing saved balances are
unchanged; use the normal project when returning to persistent-data testing.

Medical logic and isolated native checks:

```bash
LUAU_CLI=/tmp/weapon-skills-luau/luau npm run check:skills
npm run build:test-project -- --solo --medical
# Build .cache/solo-test.project.json with the installed Windows Rojo executable.
# Open the resulting place in Studio and start one ordinary Play client.
```

The medical mode runs the module regressions, `tests/runtime/MedicalSupport.luau`
and `tests/runtime/MedicalSurvival.luau` using only injected FakeProfileStore.
The survival checks cover proximity healing, direct battlefield travel and troop-average support,
critical attacks within healing range, 20%/40% recovery thresholds and an isolated
medic staying on the battlefield through real deaths/replacements. Enemy
avoidance is tested past the former three-second retreat timeout. For a focused repeat, set the
`MedicalSurvivalOnly` attribute on `ServerScriptService.SoloMedicalSupportTests`
to true before Play; module regressions still run. Watch `MedicalSupportVerificationPhase`,
`MedicalSupportVerificationResult` and `MEDICAL_SUPPORT_RESULT`. The geometry
matrix covers all eight plots, thirteen civilizations and levels 5–50 in a moved,
rotated world and can take several minutes. This mode requires `--solo` and is
exclusive with other test modes. The independent `--local-playtest` mode still
starts every civilization with 3,000 temporary coins and resets when Play ends.
Close the current Play session before starting another. Two-owner isolation and
real StudioDevelopment restoration require separate sessions; these fake fixtures
never read or write player storage.

The medical solo run also calls `MedicalCombat.luau`: four 12-second native
encounters compare one/three opponents with the medic in/out of range, then
observe an actual enemy kill and the medic's independent replacement.
`ClientTests.MedicalHUD` checks rendered text, army totals, medic countdowns and
overlap with command/skill controls. Run it in the Client context after resizing
the owned test window; it never changes player attributes or balances.

For the separate two-owner medical check, close solo Play first, generate the
ordinary test project with `npm run build:test-project`, build
`.cache/test.project.json` and open that fake-store place. From Studio's Assistant
MCP Edit context, run:

```lua
local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(
    2, {suite="medical-support"})
print(game:GetService("HttpService"):JSONEncode(result))
```

The test closes its two simulated clients/server with `EndTest`. Its observer
checks actual replicated arm positions, bandage instances and Humanoid health.
Before any isolated Play, inspect `Game.Bootstrap` and confirm it uses the supplied
fake store. An automatic connection to a production Rojo server can replace that
script after the test place opens; disconnect that sync or restore the matching
repository test bootstrap in the owned test window before starting.

## Formation checks

`npm run build:test-project -- --solo --formations` generates the isolated
formation harness. Build `.cache/solo-test.project.json`, open it in the owned
Studio window and verify its SoloBootstrap injects FakeProfileStore before Play.
Keep the Studio viewport on Client during native input. Server inspection can
switch that viewport and prevent client GUI activation. Read
`ReplicatedStorage.FormationVerificationPhase` and
`ReplicatedStorage.FormationVerificationResult` attributes from Client to monitor
the run without switching. Detailed `FormationUnitCases`/`FormationEvidence`
remain on the server DataModel. Default execution includes all module cases,
the faction runtime scenarios and four bounded-frame GUI layouts.

Set `SoloFormationsTests.FullRegression` to true before Play to add the existing
tactical combat, crowd movement and medic-survival native fixtures. For a focused
formation-only runtime rerun, `RuntimeOnly=true` omits module fixtures; restore
false for final all-module verification. Neither flag opens player storage.
Physical phone/controller play, multi-owner formation combat and real storage
restoration remain separate from these solo fake-store checks.

For Viking wedge verification, set `SoloFormationsTests.VikingOnly=true` before
Play in the formation test place. It checks physical purchases/council, shield
pickup, road march, contact/occlusion, Hold and casualties. The default formation
run includes Vikings after the earlier factions; restore `VikingOnly=false` for
that default set.
For a focused combat repeat, combine `VikingOnly=true`, `VikingCombatOnly=true`
and `RuntimeOnly=true`; restore the latter two to false for a complete run.
`PriorFormationsOnly=true` omits Viking and Seneca runtime when repeating the
earlier faction scenarios; it leaves module checks enabled unless RuntimeOnly
is also selected. Restore false for the default full formation run.

For Barracks recruitment verification, use the same formation test place and
set `SoloFormationsTests.RecruitmentOnly=true` before Play. It runs the module
checks, native recruitment prompt/count-button input, future-spawn continuity,
preserved deadlines, bare fresh spawns, physical shield collection (including
four melee), request authority and four bounded screen layouts. Set
`RuntimeOnly=true` only for a focused runtime repeat. Restore
`RecruitmentOnly=false` for ordinary formation verification; `FullRegression=true`
adds combat, crowd movement and medic-survival scenarios. All use FakeProfileStore.

For Seneca Focused Volley, set `SoloFormationsTests.SenecaOnly=true` before Play.
It exercises native purchases/council, Barracks 1/3/1 selection and future spawns,
shield absence, the unanchored crescent road march, focused staggered arrows,
visibility, bounded defense, Hold/healing, casualties and authority loss.
`SenecaCombatOnly=true` skips purchases/recruitment and the full walking route
for focused combat repeats; `ModuleOnly=true` runs only module fixtures.
Clear focused flags for the default run, which includes Seneca after Vikings.
`PriorFormationsOnly=true` omits both Viking and Seneca runtime scenarios.

For medic diagnostics in the formation harness, `MedicalOnly=true` selects only
the existing medic-survival runtime after any enabled module checks. Restore
false for formation verification. `MedicalFailureEvidence` captures positions,
goals, anchoring and navigation state before fixture cleanup on a timeout.

For minimizable panels, set `SoloFormationsTests.UIOnly=true` and
`RuntimeOnly=true` in the same fake-store formation place. After starting Play,
select the Client viewport and run this in the Client context:

```lua
game.ReplicatedStorage:WaitForChild("PrototypeTestControl",10)
    .Report:FireServer("uiFocus",{ok=true})
```

The fixture waits for this handshake before sending native input. Keep the
viewport on Client and monitor the replicated formation result attributes.
It checks all five panels, independent visibility, hidden updates, focus,
unsaved recruitment drafts, invalid building contexts and four bounded layouts.
`UIGameplayOnly=true` skips building-menu scenarios for a focused repeat. Clear
UIOnly, UIGameplayOnly and RuntimeOnly afterward. See [panel behavior](UI.md).
