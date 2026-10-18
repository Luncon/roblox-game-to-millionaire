# Weapon-family skills

Weapon skills are implemented. Their original tuning passed solo Studio combat checks;
the October 16 responsiveness/player-animation correction requires a fresh Studio run;
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
| Spear / javelin / pilum | Dash Thrust | 8 seconds | Immediate grounded dash up to 12 studs in 0.20 seconds; strike the first hostile in the forward path; stop at obstacles/battlefield bounds |
| Axe | Whirlwind | 12 seconds | Immediate contact and a 0.35-second spin; at most three visible hostiles within 6 studs, once each |
| Sword | Double Slash | 9 seconds | Immediate first contact and a second at 0.24 seconds, with broad opposing cuts against one target life; each must remain visible, in reach and in front |

Dash Thrust uses a forward body lean, an extended spear hand and driving legs.
The spear arm counters torso tilt to keep the tip level and pointed down the dash.
A short tapered tip trail emphasizes travel; it adds no collision or gameplay force.
These visual adjustments still require native Studio review.

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
In Spartan Shieldwall and Persian Archer Screen, captured front-line melee use a stationary spear thrust
instead of dashing: one ordinary-melee-range contact, the same purchased damage
tier and eight-second cooldown, and an upper-body thrust with planted legs.
Roman Shield Guard front-line melee retain the stationary two-contact Double Slash
with its normal purchased damage and cooldown. Formed ranged troops keep ordinary
attacks and cannot activate weapon skills.

The table uses ordinary single-hit damage, including the existing 0.8 ranged
multiplier for ranged actors. At weapon 50, melee tier V deals 30.6 for a dash,
21.6 per spin target (64.8 maximum across three), or 15.3 + 17.1 for the combo.
Fractional damage is preserved. These are starting balance values, not measured
proof of time-to-kill or live balance.

Skills replace ordinary attacks only during their active animation. There is no
windup or separate recovery pause: movement and ordinary attacks resume at action
completion. Network transit still applies to server-authorized player activation.
Player R6/R15 poses override ordinary animation Transforms while active, preserve
rest joints/grips, and start a cosmetic preview immediately on eligible input.
Server-approved reliable starts also drive observer playback on a local clock,
so the complete short pose can render even if the server action ended in transit.
Acceptance never restarts an already played preview; rejection releases it.
Visual timing does not change server movement, action locks, damage or cooldowns.
A started cooldown alone does not prove that an animation or hit occurred. They grant no stun,
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
