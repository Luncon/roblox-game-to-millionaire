# Civilization Battlefield

A Roblox game in which eight players build civilization-themed settlements
around a shared battlefield, fight alongside NPC armies, and command formations.
Progress is saved separately for each player's civilizations.

The first playable prototype includes eight circular settlement plots, a
Sparta/Britain selector, exclusive server-owned claims, placeholder settlements,
and respawning at your claimed plot. Claims last for the current server session.
Progress saving, other civilizations, matchmaking, armies, upgrades, formations,
and combat are planned.

Start with [Start here](START_HERE.md), the [setup guide](docs/SETUP.md),
the [prototype playtest guide](docs/PLAYTEST.md), and the [game vision](docs/GAME_VISION.md).

## Development tooling

In WSL, from this folder:

```bash
nvm use
npm ci
npm run check
npm run openspec -- list --specs
```

Node.js 24.21.0 and npm 12.0.2 are the pinned reference toolchain.
OpenSpec 1.14.1 is installed locally and locked in `package-lock.json`.
Node runs tools; Roblox Studio runs the Luau game.

## Planning and notes

- `openspec/specs/`: implemented requirements.
- `openspec/changes/`: proposed features and their implementation tasks.
- `docs/`: design decisions, references, and playtest notes.
- `.obsidian/`: shared vault settings; open this repository as an Obsidian vault.
- `.agents/skills/`: generated OpenSpec workflows for Codex.

The current gameplay change and verification checklist are in
[civilization-selection-prototype](openspec/changes/civilization-selection-prototype/tasks.md).
Use `$openspec-propose` to plan the next small gameplay change. The six generated
skills may require restarting the coding client to be discovered.

See [Dependency review](docs/DEPENDENCY_REVIEW.md) for the current upstream
audit finding. `npm run check` validates specs; it does not run gameplay tests.
