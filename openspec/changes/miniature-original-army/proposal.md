# Proposal

## Why

The first outpost slice uses simplified figures and AI rather than the original
game's outfits, rigs and animations. Troops also hover and move too quickly.
Restore the original army identity and baseline behavior at miniature scale.

## What Changes

- Reuse the original WarriorRig creation/animation, five custom melee templates,
  all thirteen outfit sets and existing equipment imports, scaled to one quarter.
- Reuse original target selection, engagement reservations, windup/contact/
  recovery, movement spacing, ranged retreat and medic planning for outpost combat.
- Ground posed feet on the actual support surface, including raised settlement
  plots, with joint-driven walking rather than whole-model bobbing.
- Slow player troops to6studs/second and neutral defenders to4. Halve current
  ranged reach20→10(player)/18→9(neutral) and healing reach14→7.
- Retain10troops, building-owned replacements, protected homes and the existing
 20-clear-second capture/E targeting loop.

Confirmed: original behavior, models, outfits, animations, grounded feet, slower
movement and half ranged/medic distance. Implementation choices: keep quarter
scale and baseline original level-one equipment; existing progression-gated
formations/skills remain with later progression. No new research or roster UI.

## Capabilities

### New Capabilities

- `miniature-original-army`: original troop source assets, animations and tactical
  behavior adapted to smaller grounded armies and bounded outpost objectives.

### Modified Capabilities

None in the main specs. This follows the separately tracked miniature combat
change without rewriting the production army, bootstrap or original assets.

## Impact

Add explicit read-only helper/asset mappings to the sandbox, original-army adapters,
scaled pose/grounding logic, real-module logic tests and native rig/outpost checks.
Preserve production code/mapping, saved schemas, preview, backup and player input.
No real stores, public deployment, new dependencies or conquest rewards.
