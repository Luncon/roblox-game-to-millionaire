# Working in this repository

This is a Roblox game written in Luau. Node.js runs development tooling only.
Read `docs/GAME_VISION.md` for the agreed game direction and `docs/SETUP.md`
for the Windows/WSL workflow.

- Use the pinned Node version in `.nvmrc` and install tools with `npm ci`.
- Run OpenSpec through `npm run openspec -- <arguments>` so the local pinned
  version is used. Run `npm run check` to validate specifications.
- OpenSpec's Codex workflows are in `.agents/skills/openspec-*/SKILL.md`.
  Follow the appropriate workflow for proposed features and implementation.
- `openspec/specs/` describes implemented behavior. Proposed game features
  belong in `openspec/changes/`; do not mark planned gameplay as implemented.
- Keep ideas, historical references, and playtest notes in `docs/`. Obsidian
  edits these same Markdown files; do not maintain duplicate specifications.
- `default.project.json` maps `src/server`, `src/client`, and `src/shared`
  into Studio. Edit managed scripts in the repository and sync them with Rojo.
- Keep server authority over currency, purchases, damage, civilization claims,
  and saved profiles. Never accept client-provided balances or ownership.
- Keep progress isolated by player and civilization. A failed load must not
  overwrite existing progress with a fresh profile.
- Verify game behavior in Studio. A Rojo build or OpenSpec validation alone
  does not demonstrate that gameplay works. Teleports need Roblox client tests.
- Keep each change small enough to playtest. Report what was checked and any
  required runtime checks that could not be completed.
- Keep dependency installation scripts disabled. Review the known OpenSpec
  dependency finding in `docs/DEPENDENCY_REVIEW.md` before tool upgrades.

The current prototype offers 13 civilizations, exclusive claims, eight generated
plots, themed settlements/equipment, and physical tycoon pads for single-coin
earning and separate settlement/weapon/armor upgrades. The HUD displays progress;
there is no client earning/purchase remote. Progress survives character resets
but remains session-only by the user's explicit choice. See `docs/ECONOMY.md`
and `docs/PLAYTEST.md`. Stage-two settlements unlock a one-slot automatic melee
barracks; three stage-gated purchases reduce future respawn waits by 0.5s each
and level IV adds one ranged slot. Owner gear applies to both classes. Player
melee and server-validated final hits award 10 coins, with shared damage/reward
authority. Weapon, armor and barracks levels are capped at settlement level;
new tier pads appear at stages 2/3/4. Five user-provided R6 melee templates live
in `assets/npc-templates`, mapped into ServerStorage by Rojo. Clone/sanitize
templates without mutating originals. Claimed-plot identity is incorporated
into each civilization's main hall facade. See `docs/ARMY.md`.
Persistence, matchmaking, formations, abilities and ranged player attacks remain planned.
