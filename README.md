# Civilization Battlefield

A Roblox game in which eight players build civilization-themed settlements
around a shared battlefield and fight alongside NPC armies. Formation commands
remain planned.
Saved profiles preserve separate progress for each player's civilizations.

The playable prototype has a 1,600 × 1,600-stud world with eight spaced plots,
13 civilization choices and five biomes around a shared battlefield. Settlements
grow from 60 to 256 studs through 50 levels, adding themed districts and landmarks.
Weapon and armor tracks also have 50 gradual levels: melee damage rises from
10 to 18 and standard maximum health from 100 to 140. Physical tycoon pads earn
one coin per activation and buy separate upgrades. Coins and upgrade levels save
independently for every civilization; use the HUD to switch to an available
civilization while keeping your plot. Settlement stage 2 unlocks a barracks with
one automatic melee warrior, which inherits weapon/armor upgrades. Barracks
retains four levels: its upgrades shorten replacement waits by 0.5 seconds each,
and level IV adds a ranged troop for a maximum of two living units. Player melee
attacks
and troop kills award 10 coins for the final hit. Settlement growth unlocks new
physical upgrade pads. Matchmaking, formations and abilities remain planned.

Start with [Start here](START_HERE.md), the [setup guide](docs/SETUP.md),
the [prototype playtest guide](docs/PLAYTEST.md), the
[saved-profile guide](docs/PROFILES.md),
the [world and settlement guide](docs/WORLD.md), and the [game vision](docs/GAME_VISION.md).

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

The current world and progression change and verification checklist are in
[expanded-world-and-settlement-growth](openspec/changes/expanded-world-and-settlement-growth/tasks.md).
See [economy and gear tuning](docs/ECONOMY.md) for prices and prototype limits.
The [army guide](docs/ARMY.md) explains barracks, inherited gear, and arena combat;
[barracks-warriors](openspec/changes/barracks-warriors/tasks.md) tracks that initial change. Earlier progression work is in
[army-progression-and-rewards](openspec/changes/army-progression-and-rewards/tasks.md).
The [profile and switching milestone](openspec/changes/civilization-profiles-and-switching/tasks.md)
tracks persistence implementation and verification. Studio saves use a separate
development scope; automated tests inject a fake store. See the saved-profile
guide for failure states and the limits of the current verification.
Use `$openspec-propose` to plan the next small gameplay change. The six generated
skills may require restarting the coding client to be discovered.

See [Dependency review](docs/DEPENDENCY_REVIEW.md) for the current upstream
audit finding. `npm run check` validates specs; it does not run gameplay tests.

Weapon, armor, and barracks tiers are capped by your settlement level. Upgrade
the settlement to reveal higher-tier floor buttons. Civilization and owner names
are incorporated into each main building’s themed facade.
