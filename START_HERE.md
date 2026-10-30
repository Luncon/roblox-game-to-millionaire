# Start here

This repository is our Obsidian vault. Use this page to find the current work,
record ideas and decisions, and return to the detailed project documentation.

## Current work: miniature main game and military research

Normal-sized, unarmed commanders oversee miniature civilization scenery and
actors. The default playable game now includes all thirteen prototype art
kits, building placement, worker production, trade and the first army combat/
outpost-capture loop. Military research and army controls now follow the updated reference guide. Progress remains temporary fake data.
Troops now reuse original outfits, models, joint animations and baseline tactics,
with grounded feet, slower movement and shorter ranged/healing reach. The original Spartan
scale preview remains a separate launch option.

The latest sandbox adds smooth troop interpolation, near-peer neutral defenders,
developed capturable frontier camps and double commander walking speed.

- [Main build, military research and army controls](docs/notes/Military%20Research%20and%20Army%20Control.md)
- [Game direction](docs/GAME_VISION.md)
- [Current mounted-army implementation and imported-model audit](docs/notes/Mounted%20Army%20Implementation.md)
- [Mount refinements, ragdoll deaths and uncapped structures](docs/notes/Mount%20Refinements%20and%20Ragdoll%20Deaths.md)
- [Current smooth-army, neutral-balance and outpost-scenery work](docs/notes/Smooth%20Armies%20and%20Frontier%20Outposts.md)
- [Playable sandbox: opening, controls and verification](docs/MINIATURE_GAMEPLAY.md)
- [Latest original troop restoration, grounded movement and range tuning](docs/notes/Original%20Miniature%20Army.md)
- [Current miniature combat, capture rules and army targeting](docs/notes/Miniature%20Combat%20and%20Outposts.md)
- [Current compact shop, automatic troop buildings and larger map](docs/notes/Simple%20Shop%20and%20Automatic%20Troops.md)
- [Inventory, automatic civilians and shared shops](docs/notes/Miniature%20Inventory%20and%20Shared%20Shops.md)
- [Thirteen civilization evidence sheets](docs/notes/Miniature%20Civilization%20Evidence%20Sheets.md)
- [Miniature preview: opening, controls and verification](docs/MINIATURE_PREVIEW.md)
- [Preserved production build and backup](docs/BACKUPS.md)
- [Project notes and decisions](docs/notes/INDEX.md)

## Using the vault

Open this page in Obsidian. Follow links to read or edit the same files used by
the repository. Create new notes in `docs/notes/`, give them descriptive names
such as `2026-10-28-miniature-playtest.md`, and link them from the
[notes index](docs/notes/INDEX.md). Include what you observed, what was decided,
and what remains open. Put reference images in `docs/assets/`.

Approved implementation requirements belong in `openspec/changes/`;
`openspec/specs/` describes implemented behavior. Link to those files from notes
instead of maintaining a second specification.

## Development and existing production game

- [Windows/WSL, Studio, Obsidian, OpenSpec and Rojo setup](docs/SETUP.md)
- [World and settlement geometry](docs/WORLD.md)
- [Economy and upgrades](docs/ECONOMY.md)
- [Army, recruitment and formations](docs/ARMY.md)
- [Weapon skills](docs/WEAPON_SKILLS.md)
- [Saved profiles](docs/PROFILES.md)
- [Interface panels](docs/UI.md)
- [Playtest evidence and remaining runtime checks](docs/PLAYTEST.md)
- [Development-tool dependency findings](docs/DEPENDENCY_REVIEW.md)

Keep at most two Studio playtests open: the user's session and one isolated
verification run. Prefer solo checks and close owned test windows afterward.
