# Start here

This folder is both the development repository and an Obsidian vault.

- [Set up Studio, OpenSpec, Obsidian, and Rojo](docs/SETUP.md)
- [Read the agreed game direction](docs/GAME_VISION.md)
- [Explore the expanded world and fifty-level settlements](docs/WORLD.md)
- [Playtest the civilization selection prototype](docs/PLAYTEST.md)
- [Use the tycoon buttons and upgrade equipment](docs/ECONOMY.md)
- [Unlock the barracks and upgrade your warrior](docs/ARMY.md)
- [Continue saved civilizations or switch to another](docs/PROFILES.md)
- [Review development-tool dependency findings](docs/DEPENDENCY_REVIEW.md)
- [Read the implemented tooling specification](openspec/specs/development-workflow/spec.md)

Write new ideas and playtest observations in `docs/notes/`. Attach reference
images in `docs/assets/`. Keep approved implementation requirements in OpenSpec.

Start Rojo, connect its Studio plugin, and press Play. Wait for your profile to
load and choose a civilization. Use the physical buttons on your plot to earn
coins and buy settlement, weapon, and armor upgrades through level 50. Settlement
stage 2 deploys your first melee warrior. Upgrade the barracks three times to add
a ranged troop; activate your equipped weapon to fight and earn 10 coins for a
final hit. Coins and upgrades save separately for every civilization.
Use **Change civ** in the HUD to choose another available civilization and keep
your plot, or return to an earlier civilization's progress. A failed profile load
blocks selection instead of resetting your progress; the selector offers Retry.
See the playtest guide for expected behavior and tests.

The 1,600 × 1,600-stud world spaces eight plots around a shared battlefield, with
grassland, forest, desert, snowy highlands and wetlands. Each settlement starts
60 studs wide and grows gradually to a 256-stud themed settlement. Weapon damage
increases from 10 to 18 and standard maximum health from 100 to 140 across 50
levels; barracks remains four levels with one melee and one ranged slot at most.

Keep one Studio playtest open at a time. Prefer solo checks and close owned test
windows before starting another run; add clients only when the behavior needs them.

Weapon, armor, and barracks tiers are capped by your settlement level. Upgrade
the settlement to reveal higher-tier floor buttons. Civilization and owner names
are incorporated into each main building’s themed facade.
