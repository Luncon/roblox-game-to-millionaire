# Working in this repository

The miniature game is now the default Clash of Civilizations development build.
`default.project.json` maps `prototypes/miniature/game`; the preserved full-size
game uses `legacy-fullscale.project.json`. Keep the clean `miniature.project.json`
scale preview and dated backups. Main miniature startup remains Studio-only with
injected FakeProfileStore; do not silently enable public servers or real storage.

The preserved full-size game's five interface panels support client-session minimization through
PanelVisibility: settlement HUD, army controls, civilization selection, Barracks
and War Council. Keep logical availability separate from physical visibility.
Hidden menus retain drafts and continue life/range/building/civilization guards;
HUD minimization must not revoke army commands. No profile fields or gameplay
requests are involved. See docs/UI.md and native UI checks in docs/SETUP.md.

This is a Roblox game written in Luau. Node.js runs development tooling only.
Read `docs/GAME_VISION.md` for the agreed game direction and `docs/SETUP.md`
for the Windows/WSL workflow.

- Use the pinned Node version in `.nvmrc` and install tools with `npm ci`.
- Run OpenSpec through `npm run openspec -- <arguments>` so the local pinned
  version is used. Run `npm run check` to validate specifications.
- Install pinned Selene, StyLua and Lune with `npm run setup:tools`; run
  `npm run check:dev` for changed-file lint/format checks and automated tests.
  Full scans use `npm run lint:all` and `npm run format:check:all`. See
  `docs/SETUP.md` for scope, existing diagnostics and Studio verification boundaries.
- OpenSpec's Codex workflows are in `.agents/skills/openspec-*/SKILL.md`.
  Follow the appropriate workflow for proposed features and implementation.
- `openspec/specs/` describes implemented behavior. Proposed game features
  belong in `openspec/changes/`; do not mark planned gameplay as implemented.
- Keep ideas, historical references, and playtest notes in `docs/`. Obsidian
  edits these same Markdown files; do not maintain duplicate specifications.
  Use `START_HERE.md` as the vault home; add project notes under `docs/notes/`
  and link new notes from `docs/notes/INDEX.md`.
- `default.project.json` maps miniature server/client/shared code into Studio.
  `legacy-fullscale.project.json` retains `src/server`, `src/client`, `src/shared`.
  Edit managed scripts in the repository; use a fresh matching place when switching builds.
- Keep server authority over currency, purchases, damage, civilization claims,
  and saved profiles. Never accept client-provided balances or ownership.
- Keep progress isolated by player and civilization. A failed load must not
  overwrite existing progress with a fresh profile.
- Verify game behavior in Studio. A Rojo build or OpenSpec validation alone
  does not demonstrate that gameplay works. Teleports need Roblox client tests.
- Keep at most two Studio playtests open at a time, allowing the user's playtest
  and one isolated verification run together. Prefer solo checks; use extra clients
  only when required by the behavior under test, and close owned test windows
  when verification finishes.
- Keep each change small enough to playtest. Report what was checked and any
  required runtime checks that could not be completed.
- Keep dependency installation scripts disabled. Review the known OpenSpec
  dependency finding in `docs/DEPENDENCY_REVIEW.md` before tool upgrades.

The following details describe the preserved full-size game in
`legacy-fullscale.project.json`. Current miniature behavior and native evidence
are documented in `docs/MINIATURE_GAMEPLAY.md` and its linked notes.

The preserved full-size prototype offers 13 civilizations, exclusive claims and eight spaced
plots in a 1,600-stud square world with five biomes. Settlements grow from 60 to
256 studs through 50 levels with themed districts and landmarks. Weapon and armor
also have 50 gradual levels: melee damage 10–18 and standard maximum health
100–140. Physical tycoon pads provide 50-coin earning and separate upgrades.
See `docs/WORLD.md` for geometry and construction. The HUD displays progress;
there is no client earning/purchase remote. Coins, progression, building levels,
farm reserve and extra troop class
save independently for each player's civilizations. Selection
waits for a writable profile; a lost lease blocks earning, purchases and kill
credits. Switching to a free civilization preserves the plot and restores its
saved progression. See `docs/PROFILES.md`, `docs/ECONOMY.md` and `docs/PLAYTEST.md`.
Stage-two settlements unlock a one-slot automatic melee barracks with six
upgrade levels. Five stage-gated purchases reduce future respawn waits by 0.5s each
and level IV adds one ranged slot. Owner gear applies to both classes. Player
melee and server-validated final hits award 10 coins, with shared damage/reward
authority. Weapon, armor and barracks levels are capped at settlement level;
only the next eligible tier pad appears; capped, completed and progression-locked
pads are absent. Distributed controls sit beside their corresponding buildings.
Armory visuals appear at settlement 2; purchased Training Yard I unlocks at 5,
Farm I/Worker Camp I at 7 and Army Camp I at 10. Entering 10 requires Barracks IV
and the first training/farm/worker buildings; legacy saved levels 10+ remain valid.
Farm II and Worker Camp II unlock at 12; workers cannot exceed the farm tier.
Production is farm level plus worker level coins per five active seconds.
Blacksmith/Armorer I at 13 discount only weapon/armor prices by 5% with upward
rounding; never change their combat stats. Storehouse I at 16 requires a farm
and raises reserve capacity from 60 to 180. Use storageCapacity(state) everywhere
the cap matters. Farm/worker/storage purchases settle old-yield/old-capacity
whole intervals then reset the clock; never bank full, offline or inactive time.
Save all twenty scalar fields, with missing-only zero defaults for the three
workshop/storage fields, skillLevel and hospitalLevel, and unchanged version-one keys. Barracks V/VI require
settlement 8/14, cost 200/300 and set future delays to 13/12.5 seconds; they
preserve two barracks slots, pending deadlines and the optional camp slot.
Rural fields reserve space outside the final plot
and battlefield; passive tending workers remain anchored and outside combat
registration. The supplied R15 farmer uses a fresh disabled Humanoid only for
classic clothing rendering (explicitly approved by the user); its state machine,
autorotation and movement are disabled.
Army Camp I adds one independent third slot; its saved melee/ranged selection
applies only at next spawn and never resets health or pending respawn timers.
Training unlocks server-guarded advance/hold/regroup, with server-chosen rally
positions and transient orders. See `src/shared/SettlementDevelopment.luau`.
Five user-provided R6 melee templates live
in `assets/npc-templates`, mapped into ServerStorage by Rojo. Clone/sanitize
templates without mutating originals. Claimed-plot identity is incorporated
into each civilization's main hall facade. See `docs/ARMY.md`.
Nineteen cosmetic models in `assets/equipment-templates` map to
ServerStorage.EquipmentTemplates and cover every current weapon role. Thirteen
outfits in `assets/outfit-templates` map to ServerStorage.OutfitTemplates for
players and generated troops. EquipmentVisuals rebuilds inert clones; never
import their gameplay scripts, source rigs or stats. The five custom melee skins
retain their original headwear and clothing. OutfitTemplates preserves avatar
wardrobe restore baselines and later external edits; native late appearance
loading must force reapplication without clearing those baselines. See
`assets/README.md` for attachment conventions and `docs/MARKETPLACE_ASSETS.md`
for source IDs, creators and dated free-price verification. Automated fixtures
must preserve unrelated avatar items and immutable source models.
TroopAppearance applies civilization-specific skin-tone art defaults and warrior
face texture `10526794` after NPC equipment updates, including custom melee
clones. Keep BodyColors and actual body-part colors consistent, exactly one
front face, and existing head meshes/proportions/clothes/headwear. Never mutate
source templates or apply this NPC override to player avatars. Palette defaults
do not describe every historical person; baked clothing skin colors remain.
ProfileService uses `CivilizationProfilesV1` with `StudioDevelopment` in Studio
and `Live` in Roblox servers. Automated tests must inject their fake store; never
run regression fixtures against player data. Real storage verification is separate
from fake-store checks. NPC combat shares server-owned target selection, engagement reservations, local
separation and bounded ranged retreats across both troop services. Shared soft
spacing also covers Advance, Regroup and camp walks; detours retain medic movement
and healing-range constraints. Idle shuffles and optional recovery footwork yield
to planted windup/contact, skills and Hold; intentional traffic waits never trigger
stuck jumps. Windup/contact/
recovery drives exactly-once validated strikes and weapon-family R6 poses; preserve
source joints, equipment grips and distinct imported/neutral/fallback bow bases.
Hold remains stationary; Regroup cancels pending contacts and shots. Weapon-family
skills use server-authoritative contacts, cooldowns and five paid tiers requiring
Training Yard I and weapon levels 10/20/30/40/50. Players activate with R; eligible
owned troops activate automatically. Regroup cancels skills, and Hold prohibits
dash skills. Preserve ordinary attack exclusion, source grips and pending respawns.
Matchmaking, additional formations, civilization-specific abilities, mounts and ranged player
attacks remain planned. See docs/WEAPON_SKILLS.md for verification boundaries.

The generated landscape uses deterministic connected native geometry with
asymmetric relief. `Topography` samples the same local triangles used for
collision; use its height sampler when grounding scenery. Final plots, radial
troop roads and crossing reservations remain flat. Arena relief is capped at
six studs inside the unchanged combat height band. Keep the complete landscape
within 2,000 static BaseParts and preserve global Terrain/developer geometry.

Hospital I requires settlement 10 and Training Yard I, costs 200, and adds an
independent fourth medic slot with a fixed 15-second respawn. The hospital and
its pad/access reserve a rear site through SettlementSites/Topography. Medics
are targetable registered actors but must be rejected by all offensive dispatch.
Advance sends medics directly to the battlefield, then toward the living owned
fighter average without backtracking. Only fighters inside the battlefield affect
positioning/coverage; outside replacements never block Advance. With none on the
field, retain the forward battlefield destination. Healing runs independently while moving;
only actual enemy avoidance or Regroup allows backward travel. Do not restore
escort, patient-chase, timed retreat or barracks fallback logic.
During real enemy avoidance, slightly prefer routes toward wounded allies already
on the field, within two studs of best endpoint clearance. Check enemy clearance
along the full step; healthy, outside, foreign or stale fighters cannot attract it. Hold remains
stationary and permits fighter attacks plus medic healing. Regroup cancels
bandages and uses distinct medic camp arrival index 6. MedicalService owns
12-HP/45-stud/three-second bandages and hospital-gated five-HP/second yard recovery
after two undamaged seconds. Fresh registered life/claim/authority checks are
mandatory; no players, foreign troops, revival, offline healing or rewards.
Medical clocks/health never save. See docs/ARMY.md and medical verification
boundaries in docs/PLAYTEST.md; fake fixtures do not establish native gameplay.

Army Camp II (settlement 18, 250 coins, Barracks VI/Camp I) adds a fixed fifth
melee slot for all civilizations; War Council I (19, 200, Training I) adds an
accessible map room beside camp. Sparta, Rome and Persia buy Shield Training I (15, armor
15/Armorer I, 150) and their own Shieldwall/Shield Guard/Archer Screen formation (20, 250,
council/shields/camp II/hospital).
Save shieldLevel, warCouncilLevel, formationLevel and selectedFormation with
missing-only defaults (zero/none); retain twenty-field version-one compatibility.
The council guards living owner, write authority, faction/unlock and map distance.
March Formation requires all five current correct troop lives in owned camp;
assemble at the road center, then march at six studs/second in the faction
layout: Spartan convex front/support pair, compact Roman guard with outward
flanks, or straight Persian archer screen. Hold attacks/heals, Advance abandons,
Regroup cancels. Sparta/Rome release at final center arrival. A captured frontline
casualty releases ordinary Advance unless explicitly held. Support losses remove only that captured life; replacements
never silently join. Stationary formation skills use spear thrust for Sparta/Persia
and Double Slash for Rome; formed ranged troops keep ordinary attacks.
Shields share player/melee visuals and block two validated frontal hits per life.
Rebuilds/upgrades/same-life civilization switches never refill charges. No bonus
stats, client authority, persisted charges or persisted march phases.
The normal Studio build has a +1,000 TEST COINS pad beside the earning pad.
Owner/life/proximity/write checks and a half-second grant cadence apply; both
pad creation and the fixed-amount economy grant reject non-Studio environments.

Persian Archer Screen uses a straight front with paired rear support. It latches
a deployed screen at a clear captured-archer shot within 40 studs or at its final
destination; melee defend within six studs of their slots. Existing Sparta/Rome
center release stays unchanged. Purchased shield training builds a rack north of
camp; recalled living owned melee with zero charges physically replenish there
before normal camp return. Partial shields and player shields are not refilled.
Preserve weapon/grip identity, health, cooldowns and timers; pickups require
Regroup, current ownership/civilization, write authority and assigned proximity.
No new persistent fields or charge-refill path through ordinary equipment sync.

Recruitment consolidation: the Barracks now owns both extra combat capacity
purchases (legacy `armyCampLevel` storage key), with unchanged unlocks/prices.
The Army Camp building is removed. Barracks and both upgrade pads stand beside
Training Yard opposite War Council. Owner-only nearby recruitment controls save
optional `recruitMelee/recruitRanged/recruitMedic` together; all missing preserves
the old automatic lineup. Custom fighter totals are bounded by purchased
capacity, ranged requires Barracks IV, and medics remain hospital-limited to one.
Keep living troops and pending respawn deadlines when changing selections;
disabled slots stop replacement, not living units. Canonical 3/1/1 maps to existing
formation IDs. Fresh eligible melee defer shields and physically collect at the
owned rack before joining orders; Hold pauses, lost authority blocks pickup.
Persian screen deploys at 30 studs and latches half-speed approach after a clear
45-stud bow opportunity. Persian spear flip affects cloned visuals only.

Vikings also unlock Shield Training and Viking Shield Wedge at the shared
progression gates/prices. Three axe shieldmen form a pointed six-stud lead with
axe thrower/medic paired behind, at the unchanged six-stud marching pace.
Only the Viking wedge releases on server-validated captured-frontline melee
reach (five studs, hostility, arena, visibility and authority), even during
assembly or a cohesion stall. Explicit Hold suppresses contact release and
permits stationary attacks/healing. Center arrival/frontline casualties and
Advance/Regroup use the existing transitions; no bonuses or new saved fields.

Seneca Focused Volley is shieldless: settlement 20/250 coins requires Council I,
Barracks Capacity II and Hospital I, with no Shield Training or armor prerequisite.
Japan and Seneca never receive shield purchases, racks or charges. A captured
1 melee/3 ranged/1 medic roster assembles and marches at six studs/second in a
20-stud crescent, deploying on a clear captured-archer shot within 40 studs or at
center. SenecaVolley retains a current legal shared target and spaces ordinary
archer windup starts by at least .45 seconds; individual range, cooldown, visibility,
authority and contact validation remain unchanged. The guard intercepts within
14 studs of its slot; archers reposition within eight. Hold attacks/heals without
movement; Advance/Regroup cancel. Guard loss or all captured archers lost releases
ordinary Advance unless explicitly held. Replacements never join captured lives.
No bonuses, ranged skills, new save fields or Japan formation are introduced.
