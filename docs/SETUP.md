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

`npm run build:test-project` builds an isolated test configuration whose bootstrap
injects an in-memory store. Automated regressions do not access either real scope.
Run `tests/RunPersistenceMultiplayer.luau` in that test place through Studio's
Assistant MCP Edit context to check independent progress, switching, fresh Studio
sessions, failed loads and bounded retry traffic with two clients. Real Roblox
storage restoration is recorded separately in [the playtest log](PLAYTEST.md).
