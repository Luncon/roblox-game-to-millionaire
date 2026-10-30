# Clash of Civilizations

The default build is the miniature civilization game: place buildings, produce
and sell goods, and send small armies to conquer outposts. Build
`default.project.json`; see [launch and controls](docs/MINIATURE_GAMEPLAY.md).
Development is Studio-only with temporary injected fake profiles.
Military research includes29themed upgrades, a hex tree, editable army groups
and outpost deployment. [Rules and native evidence](docs/notes/Military%20Research%20and%20Army%20Control.md)
are maintained in the shared Obsidian vault.

The original full-size game remains available through
`legacy-fullscale.project.json`. The description below records that legacy build.

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
has six levels: its upgrades shorten replacement waits by 0.5 seconds each,
and level IV adds a ranged troop for two barracks units. Army Camp I at settlement
10 adds a third troop with a saved melee/ranged choice. Training Yard I at 5
unlocks Advance, Hold and Regroup; Farm I and Worker Camp I at 7 supply online-only
income collected beside the rural fields. Their second tiers at 12 raise
production to four coins per five seconds; separate workshops at 13 discount
gear prices and a storehouse at 16 raises reserve capacity to 180. Barracks V/VI
at 8/14 shorten future respawns to 13/12.5 seconds while keeping the same slots.
Player melee attacks and troop kills award 10 coins for the final hit. Settlement growth unlocks new
physical upgrade pads beside each building; locked purchases remain hidden.
Entering settlement 10 requires Barracks IV and the first training, farm and
worker buildings. Matchmaking, formations and abilities remain planned.

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
Building progression, farming and army controls are tracked in
[settlement-development-milestone](openspec/changes/settlement-development-milestone/tasks.md).
The next economic tiers and workshops are tracked in
[settlement-economy-expansion](openspec/changes/settlement-economy-expansion/tasks.md).
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
