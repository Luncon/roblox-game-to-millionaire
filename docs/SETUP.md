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
[dependency review](DEPENDENCY_REVIEW.md) for the known upstream audit finding.

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

Reference: [Obsidian vaults](https://obsidian.md/help/vault).

## Rojo on Windows

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
| `src/server/` | `ServerScriptService/Game` |
| `src/client/` | `StarterPlayer/StarterPlayerScripts/Game` |
| `src/shared/` | `ReplicatedStorage/Shared` |

The mapping leaves Workspace and other services under Studio's control, so you
can build the map there. Edit mapped scripts in the repository; normal live sync
sends those edits into Studio. It does not automatically save Studio script edits
back into these files. Save your Studio place separately to preserve map edits.

An offline script build can be produced with:

```powershell
New-Item -ItemType Directory -Force build
& "C:\Users\smitl\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" build default.project.json -o build\civilization-battlefield.rbxlx
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

Keep one Studio playtest open at a time and use solo Play for ordinary checks.
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

## Saved civilization profiles

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

Run `npm run check:skills` for deterministic logic tests, including skills,
economy, profile validation and fake-store restoration. The runner detects the
Mac install or uses `luau` from PATH; `LUAU_CLI` can specify another executable.
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
itself. Normal `default.project.json` startup and existing saved balances are
unchanged; use the normal project when returning to persistent-data testing.

Medical logic and isolated native checks:

```bash
LUAU_CLI=/tmp/weapon-skills-luau/luau npm run check:skills
npm run build:test-project -- --solo --medical
# Build .cache/solo-test.project.json with the installed Windows Rojo executable.
# Open the resulting place in Studio and start one ordinary Play client.
```

The medical mode runs the module regressions and `tests/runtime/MedicalSupport.luau`
using only injected FakeProfileStore. Watch `MedicalSupportVerificationPhase`,
`MedicalSupportVerificationResult` and `MEDICAL_SUPPORT_RESULT`. The geometry
matrix covers all eight plots, thirteen civilizations and levels 5–50 in a moved,
rotated world and can take several minutes. This mode requires `--solo` and is
exclusive with other test modes. The independent `--local-playtest` mode still
starts every civilization with 3,000 temporary coins and resets when Play ends.
Close the current Play session before starting another. Two-owner isolation and
real StudioDevelopment restoration require separate sessions; these fake fixtures
never read or write player storage.

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
