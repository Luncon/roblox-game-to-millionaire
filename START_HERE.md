# Start here

This folder is both the development repository and an Obsidian vault.

- [Set up Studio, OpenSpec, Obsidian, and Rojo](docs/SETUP.md)
- [Read the agreed game direction](docs/GAME_VISION.md)
- [Playtest the civilization selection prototype](docs/PLAYTEST.md)
- [Use the tycoon buttons and upgrade equipment](docs/ECONOMY.md)
- [Unlock the barracks and upgrade your warrior](docs/ARMY.md)
- [Review development-tool dependency findings](docs/DEPENDENCY_REVIEW.md)
- [Read the implemented tooling specification](openspec/specs/development-workflow/spec.md)

Write new ideas and playtest observations in `docs/notes/`. Attach reference
images in `docs/assets/`. Keep approved implementation requirements in OpenSpec.

Start Rojo, connect its Studio plugin, and press Play. Choose a civilization,
then use the physical buttons on your plot to earn coins and buy settlement,
weapon, and armor upgrades. Settlement stage 2 deploys your first melee warrior. Upgrade the barracks three
times to add a ranged troop; activate your equipped weapon to fight and earn
10 coins for a final hit.
See the playtest guide for expected behavior and tests.

Weapon, armor, and barracks tiers are capped by your settlement level. Upgrade
the settlement to reveal higher-tier floor buttons. Civilization and owner names
are incorporated into each main building’s themed facade.
