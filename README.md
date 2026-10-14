# Civilization Battlefield

A Roblox game in which eight players build civilization-themed settlements
around a shared battlefield, fight alongside NPC armies, and command formations.
Planned saving will preserve separate progress for each player's civilizations.

The playable prototype includes eight circular settlement plots, 13 civilization
choices, exclusive claims, themed settlements and equipped gear, and respawning
at your claimed plot. Physical tycoon pads earn one coin per activation and buy
separate settlement, weapon, and armor upgrades. Progress lasts for the current
session. Settlement stage 2 unlocks a barracks with one automatic melee warrior,
which inherits weapon/armor upgrades. Barracks upgrades shorten replacement
waits by 0.5 seconds each; level IV adds a ranged troop. Player melee attacks
and troop kills award 10 coins for the final hit. Settlement growth unlocks new
physical upgrade pads. Saving, matchmaking, formations and abilities remain planned.

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
[civilization-clicker-upgrades](openspec/changes/civilization-clicker-upgrades/tasks.md).
See [economy and gear tuning](docs/ECONOMY.md) for prices and prototype limits.
The [army guide](docs/ARMY.md) explains barracks, inherited gear, and arena combat;
[barracks-warriors](openspec/changes/barracks-warriors/tasks.md) tracks that initial change. Current progression work is in
[army-progression-and-rewards](openspec/changes/army-progression-and-rewards/tasks.md).
Use `$openspec-propose` to plan the next small gameplay change. The six generated
skills may require restarting the coding client to be discovered.

See [Dependency review](docs/DEPENDENCY_REVIEW.md) for the current upstream
audit finding. `npm run check` validates specs; it does not run gameplay tests.

Weapon, armor, and barracks tiers are capped by your settlement level. Upgrade
the settlement to reveal higher-tier floor buttons. Civilization and owner names
are incorporated into each main building’s themed facade.
