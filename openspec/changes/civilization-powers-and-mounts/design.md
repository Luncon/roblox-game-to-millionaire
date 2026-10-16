# Design

## Context

CombatService currently combines normal attack cooldowns, validated damage and exactly-once kill rewards. PlayerCombatService supports melee; troop services use encounter windup/contact/recovery and ranged projectiles. WarriorConfig and Equipment identify weapon kinds. ProfileData copies fourteen scalar fields. Training Yard I exists at settlement 5 and enables army commands; physical purchase pads already validate ownership and writable progress. No mount runtime exists. See proposal.md for scope and sequencing.

## Goals / Non-Goals

**Goals:** implement three shared weapon-family skills across the roster, paid five-tier progression and training-camp pads, while preserving existing combat, rigs and independent profiles.

**Non-Goals for phase one:** mounts, civilization-specific attacks, ultimates, burn/slow mechanics, palette selection, ranged player attacks, new weapons or currencies. Retain the mount spec as a future phase-two contract, not current implemented behavior.

## Decisions

### Family eligibility and progression

Use a shared WeaponSkillConfig defining weapon-kind aliases, tier requirements, prices, multipliers, geometry and cooldowns. Resolve actual server-owned equipment/variant metadata rather than client-supplied family. Map spear/javelin/pilum to spear, axe to axe, and sword/sabre/katana/rapier/khopesh/gladius/kilij/dao to sword. Unknown kinds remain unsupported. Generated neutral opponents receive no skill in this milestone because they have no purchased civilization progression.

Current melee roster: Sparta/Persia/Maurya use spear; Seneca/Vikings use axe; Britain/Mongols/Japan/Spain/Egypt/Rome/Ottomans/Ming use sword. Current ranged javelin/pilum and throwing-axe troops also qualify at close range. Bows, muskets, crossbows and slings remain unchanged. NPC action selection must use a skill-specific close-range check rather than allowing ranged AI to dash/spin from its normal firing range.

One skillLevel scalar per civilization buys the first family skill for every eligible owned actor in that civilization, including an eligible ranged camp slot. The weapon determines which skill appears; this avoids charging duplicate progression for the same purchased family skill. No generic effect selector or ultimate is included.

| Skill tier | Required weapon level | Tier price | Dash | Spin per target | Sword first + second |
| --- | --- | --- | --- | --- | --- |
| I | 10 | 100 | 1.30x | 0.80x | 0.65x + 0.75x |
| II | 20 | 200 | 1.40x | 0.90x | 0.70x + 0.80x |
| III | 30 | 350 | 1.50x | 1.00x | 0.75x + 0.85x |
| IV | 40 | 550 | 1.60x | 1.10x | 0.80x + 0.90x |
| V | 50 | 800 | 1.70x | 1.20x | 0.85x + 0.95x |

Training Yard I is required at every purchase. Skill prices total 2,000 coins and receive no Blacksmith/Armorer discount. Thresholds refer to weapon upgrades, not merely settlement level; the existing weapon-to-settlement cap remains. Tiers are sequential, never automatically granted. Purchase updates eligible living/replacement units without healing, restarting cooldowns or touching troop slots/deadlines.

### Physical training-camp pad

Extend existing offers, PadCatalog and TycoonButtons using the existing training-camp site. Show only the next eligible tier, absent until both training and weapon prerequisites are met and absent at tier V. Reuse affordability colors, labels, purchase validation, physical-event rate limits and one-purchase-per-entry latches. Label the civilization's main melee skill plus its tier/price/effect; describe eligible secondary weapon families in feedback where applicable. Position the pad beside, not in, the campfire or rest paths. Recompute geometry through the existing settlement site mapping rather than hardcoding world positions.

### Authoritative skill actions

Add an action state shared by ordinary attack and skill activation. An accepted activation snapshots actor life, owner/claim generation, weapon family, purchased tier and ordinary role damage. Skills replace ordinary attacks for their full action. A narrow validated internal damage path supports two contacts or bounded area hits without admitting arbitrary client damage or bypassing actor/protection checks. Keep one existing reward guard per victim life for all contacts. Clients request activation only; targets and dash endpoints are server-selected/validated.

Cooldowns start on accepted activation, including a whiff or later cancellation. Invalid requests during cooldown, dead/unequipped state, unsupported weapon or lost authority do not start an action. Player skill deadlines persist by user/family within the server across resets and civilization switches. NPC deadlines persist by owner/slot/family across replacement and switches, so replacing a rig cannot reset a skill; new slots begin ready. Purchases never alter deadlines. Do not persist cooldowns across servers.

All contacts independently check life identity, hostility, writable source authority, arena membership, reach and line of sight. Cancellation on death, departure, switch, lease loss or Regroup prevents pending damage/movement; no recursive effects, stun, knockback or invulnerability. Hold prohibits dash movement and permits stationary skills only against valid in-range enemies. Skills do not create additional automatic troops.

### Timing, geometry and balance

| Skill | Cooldown | Initial action timing | Damage geometry |
| --- | --- | --- | --- |
| Dash Thrust | 8s | 0.20s windup, up to 0.30s dash, 0.50s recovery | Up to 10 studs forward, first valid hostile once |
| Whirlwind | 12s | 0.25s windup, 0.45s spin, 0.50s recovery | Radius 6 studs, nearest 3 valid visible hostiles once each |
| Double Slash | 9s | 0.20s windup, contacts at 0.20s and 0.55s, recovery through 1.20s | Existing 5-stud melee reach/facing, same target life for both contacts |

Resume ordinary attack scheduling no sooner than action end; never emit a buffered ordinary hit during the skill. Dash sweeps body clearance and strike contact over each movement segment, remains grounded using collision geometry/Topography where appropriate, stops before obstructions or the unchanged arena boundary and never teleports or flings. At the first hostile contact, stop and apply one strike. Spin sorts nearest valid targets with stable tie-breaking and deduplicates each life. Sword's second contact can miss and never retargets.

Compute D from the wielder's ordinary single-hit damage at activation, including the existing 0.8 ranged multiplier for ranged-class actors. Skill damage is total replacement-attack damage, not an extra normal strike. For a level-50 melee actor D=18: dash=30.6, spin=21.6 per enemy (maximum 64.8 across three), double slash=15.3+17.1=32.4. At tier I/weapon 10, D is approximately 11.469: dash=14.91, spin=9.18 per enemy, double slash=16.06 total. Preserve fractional server damage and round labels only.

Dash gains mobility with lower single-target damage than the sword combo. Spin trades single-target strength and longer cooldown for area damage. Fixed cooldowns prevent late tiers from multiplying both attack frequency and damage. These approved starting values still require measured time-to-kill, ordinary-hit displacement, chase and multi-unit tests; they are not evidence of final balance. Initial action timing is an implementation baseline to tune while preserving these damage/cooldown contracts.

### Input and animation

Provide one skill action on keyboard R, gamepad Y and an on-screen touch button, avoiding existing combat/order controls. Show skill name, purchased tier and cooldown; keep purchases on physical pads. NPCs decide automatically only when a valid target opportunity exists and ordinary action state permits it. Use coordinated encounter poses for NPC R6 rigs and player-compatible animation for R15, preserving source joints, headwear, grips and original templates. Server-approved telegraphs/contact events drive bounded visual playback. Cosmetic intensity must not change outcomes.

### Saved state

Add skillLevel integer 0–5, missing-only default 0. Require trainingLevel=1 and weaponLevel >= skillLevel*10 when positive. Extend every state copy, snapshot, save and publication path to fifteen scalar fields. Retain schemaVersion 1, CivilizationProfilesV1, StudioDevelopment/Live scopes and existing keys. Explicit invalid supplied values fail safe loading; never replace existing profiles with defaults. No meleeEffect/rangedEffect/palette fields from the superseded plan are introduced. Existing fourteen fields remain unchanged. Cooldowns, action state, targets and movement are transient.

### Phase two boundary

Keep the civilization-mounts spec as a retained future contract. Do not add mount code, models, save fields, controls or tests to phase-one tasks. Mounted integration must later preserve family skill cooldowns/action exclusion and cannot let an animal attack trigger skills. Revisit provisional mount tuning after weapon-skill playtests. Civilization specials and elemental customization remain deferred separately, with no implied automatic implementation.

## Risks / Trade-offs

- [Dash tunnels or escapes protected combat bounds] → server clearance sweeps, ground sampling and per-contact arena checks; test slopes, walls and boundaries.
- [Normal attacks overlap skills or rewards duplicate] → shared action gate and per-attack/per-contact target-life identities through one reward guard.
- [Sword second hit bypasses base cooldown incorrectly] → internal contact handling restricted to a live authorized skill action, never a public free-damage path.
- [NPC skills synchronize into excessive burst] → measure multi-unit encounters and validate telegraphs; do not lower cooldowns without new tuning evidence.
- [Old save writers omit skillLevel] → rollback only to extension-aware code with skills disabled.
- [No direct Studio tools in this session] → prepare isolated fixtures and record runtime checks pending until executable Studio/client access exists; Rojo is not gameplay evidence.

## Migration Plan

1. Land compatible fifteen-field copies/validation and fake-store migration checks.
2. Land paid training-camp offer/pad and verify purchase/restoration without altering combat.
3. Verify spear dash, axe spin and sword combo independently, then add eligible ranged troop close-range integration.
4. Run isolated solo engine checks and one necessary two-player session; record exact runtime evidence and unresolved checks.
5. Complete phase-one acceptance before phase-two mount planning/implementation. Do not archive the combined change while retained phase-two requirements remain outstanding; a separately approved split can permit independent archival.
6. Disable skills for rollback while preserving the new field and old progress. Never use regression fixtures against real stores.
