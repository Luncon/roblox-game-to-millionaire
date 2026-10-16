# Weapon-family skills

Weapon skills are implemented and have passed solo Studio combat checks;
multiplayer, additional input devices and published-client checks remain pending. They apply to both players and owned troops
using the actual equipped weapon family, independently of civilization.

Buy tiers I–V from the next eligible **skill pad beside the training camp**.
Training Yard I must be purchased first. Weapon levels, not settlement levels
alone, unlock eligibility. Each purchase applies to all matching living and
replacement units in that civilization without healing them or resetting timers.

| Tier | Required weapon level | Purchase price | Dash | Spin per enemy | Sword first + second |
| --- | ---: | ---: | ---: | ---: | ---: |
| I | 10 | 100 | 130% | 80% | 65% + 75% |
| II | 20 | 200 | 140% | 90% | 70% + 80% |
| III | 30 | 350 | 150% | 100% | 75% + 85% |
| IV | 40 | 550 | 160% | 110% | 80% + 90% |
| V | 50 | 800 | 170% | 120% | 85% + 95% |

Prices total 2,000 coins; workshops do not discount skills. Locked and completed
pads are absent. Purchases use the usual physical prompt/touch/click validation.

| Weapon family | Skill | Cooldown | Behavior |
| --- | --- | ---: | --- |
| Spear / javelin / pilum | Dash Thrust | 8 seconds | Grounded dash up to 10 studs; strike the first hostile in the forward path; stop at obstacles/battlefield bounds |
| Axe | Whirlwind | 12 seconds | One spin; at most three visible hostiles within 6 studs, once each |
| Sword | Double Slash | 9 seconds | Two contacts roughly 0.35 seconds apart against one target life; each must remain visible, in reach and in front |

Sabres, katanas, rapiers, khopeshes, gladii, kilij and dao use the sword skill.
Bow, musket, crossbow and sling roles do not receive a new skill yet. The Seneca
player currently carries a bow, while its melee troop carries an axe; only the
axe troop receives Whirlwind. Ranged javelin/pilum and throwing-axe troops can
use their family skill at close range, retaining their ordinary projectile attack
at distance. Neutral test opponents have no purchased skills.

Equip the appropriate weapon and press **R** on keyboard, **Y** on gamepad, or
the on-screen skill button on touch. The button displays the skill, tier and
cooldown, and reports rejected activation. Typing into a text box does not activate
a skill. Troops activate automatically for valid opportunities. Hold prevents
dash movement but permits in-range stationary skills. Regroup cancels skills.

The table uses ordinary single-hit damage, including the existing 0.8 ranged
multiplier for ranged actors. At weapon 50, melee tier V deals 30.6 for a dash,
21.6 per spin target (64.8 maximum across three), or 15.3 + 17.1 for the combo.
Fractional damage is preserved. These are starting balance values, not measured
proof of time-to-kill or live balance.

Skills replace ordinary attacks during animation/recovery. They grant no stun,
invulnerability, healing or extra troop slots. Accepted activation spends cooldown
even on a miss or later cancellation. Death, switch, Regroup and lost write authority
cancel pending movement/contacts. Purchases never reset cooldowns. Player
deadlines survive character resets and civilization switches per family within
the server; NPC deadlines survive replacements per owner, slot and family.

All hits use server-owned protection, target-life checks and a shared exactly-once
kill-reward path. Dash uses server-controlled movement and collision sweeps.
Source templates, equipment grips and clothing remain intact. Saved `skillLevel`
is per civilization; active actions and cooldown deadlines do not save across
servers. Mounts and civilization-specific specials remain later work.

## Verification

`npm run check:skills` runs standalone Luau logic checks with explicit engine
doubles. Install the official Luau CLI or set `LUAU_CLI` to its executable; the
runner also detects `~/.local/bin/luau`. This suite cannot verify Roblox physics,
native inputs or real storage. The Studio test project uses an injected fake store:

```sh
npm run build:test-project -- --solo --skills
rojo build .cache/solo-test.project.json -o build/weapon-skills-tests.rbxlx
```

Open the test place in the existing Studio window, keep a single solo Play run,
and inspect `WeaponSkillsVerificationPhase` and `WeaponSkillsVerificationResult`.
Real storage and multiplayer acceptance must be recorded separately in PLAYTEST.md.
