# Mount refinements and ragdoll deaths

The user requested these corrections after testing the mounted army:

- Elephant and camel movement slightly below ordinary troop speed.
- Smaller elk and only slightly smaller bears.
- Lion rider seated on the back rather than floating.
- Short, thick, block-shaped bull feet resembling the horse style.
- Visibly swaying crocodile feet.
- Black wolf eyes; rhino eyes and a stronger snout while preserving the Roblox style.
- Physical ragdoll deaths for regular troops, riders and animals.
- No aggregate structure limit, including placed structures and held building items.

Implementation is tracked under
[miniature-mount-refinements](../../openspec/changes/miniature-mount-refinements/proposal.md).
The existing [mounted foundation](Mounted%20Army%20Implementation.md) and its
historical evidence remain separate from verification of these new corrections.

## Chosen values and behavior

Elephant/camel speed is implemented at **5.5 studs/sec**, compared with ordinary
troops at **6** and other mounts at **9**. Elk overall length changes from 3.6
to **2.9 studs** (19.44% smaller); bear length from 3.5 to **3.25** (7.14% smaller). Mounted health, damage, two-slot
cost and facility price remain 300 HP, 48 damage, two slots and 5,000 Coins.

Ragdolls are cosmetic physics triggered only by a confirmed current-life combat
death. Bodies remain for six seconds, fading during the final second under fixed
model/part budgets. They do not block commanders, placement or combat queries. Reclaim,
civilization switching, lost authority and ordinary cleanup are not deaths and
must not create corpses. Dead actors leave combat/capture immediately; existing
building-owned replacement clocks and independent civilization funding remain.

The fixed twelve-structure and twelve-building-item ceilings are removed.
Legal plot space, lanes and overlap still govern placement; the army remains at
ten weighted slots. Currency, merchant stock, unique civic/storehouse semantics,
goods storage and exact finite saved counts remain guarded.

Imported templates and source outfits remain immutable. Geometry, seating and
ragdoll joints operate only on clones. Production, real storage, the clean scale
preview and the original import workbench stay outside this change.

## Verification status

The species slice passes **147 miniature logic cases**, including five new cases
using both the numeric simulation and exact original tactical adapter. They verify
5.5-speed elephants/camels, unchanged 6-speed infantry and 9-speed other mounts,
immutable per-species profiles, normal fallback/neutral scaling, 271 HP retained
on the same wounded life and an unchanged pending replacement deadline. The
eleven-template asset audit still passes with 523 immutable supplied parts.

The structure-count slice raises the complete pure suite to **152 cases**. New
regressions place and restore 23 legal buildings, buy more than twelve held plans,
reclaim into an inventory already above twelve, preserve exact integer guards,
and reject malformed/sparse saved arrays without overwriting them. Normal plot,
stock, unique items, goods capacity, workers and ten-slot army checks remain.

The [mount correction record](../assets/miniature-mount-refinements-native-2026-10-29.json)
and seven close-ups pass all thirteen original riders, 921 parts, 129 anatomical
joints, 156 grounded source poses and 294 shared-client solver poses. Focused
checks prove seated lion posture, four block-shaped bull legs, two black wolf
eyes, rhino eyes/muzzle and a minimum crocodile foot sweep around 0.74 studs.
The native Play repeats those geometry checks with the immutable source fingerprint.

The [normal-input run](../assets/miniature-refinements-paid-and-structures-native-2026-10-29.json)
buys and places a 5,000-Coin lion facility from the 20,000-Coin test wallet. Its
troop dies in real automatic combat, yields a physical animal/rider ragdoll with
24 sockets and 18 collision proxies, expires, and receives a fresh 300-HP life
under the existing replacement system. All 102 corpse parts move and rotate in
the sampled physical collapse. Weighted allocation remains two slots.

The same normal UI run buys **13 held building items** for 2,400 Coins and places
ten of them, reaching **14 physical buildings** with three held items remaining.
All 25 structure actions pass on their first attempt. Its army uses eight of ten
slots; there is no new army capacity from extra structures.

Server native checks pass exact-life death/retirement, stale and ordinary removal
guards, and the last-defender death when capture removes its actor in the same
step. Eight plot supports retain normal default collision; physical probes for
both ordinary and corpse groups land at the same ground height. Default ray and
overlap queries exclude corpse/support proxies. Original foot troops retain all
39 role appearances and 518 grounding/shared-client solver checks.

The [final native record](../assets/miniature-mount-refinements-final-native-2026-10-29.json)
and [isolated physics record](../assets/miniature-ragdoll-client-native-2026-10-29.json)
pass all five tested presentations: melee, ranged, medic, lion/rider and the large
crocodile/rider. All show physical limb articulation with rigid gear/furniture
preserved, stale/duplicate notices rejected, and replacement lives independent.
Observed fade precedes expiry; all corpse/support physics is removed on TTL,
renderer teardown and direct source-folder replacement.

Independent budget runs reach **12 small corpses / 588 parts** with two oldest
evictions, and **five large crocodile corpses / 1,125 parts** with nine evictions.
The configured limits are twelve corpses, 1,200 parts, 18 colliders and 24 sockets
per corpse, and eight shared support proxies. The support-cap case reaches eight.
Default rays ignore these physical proxies, and a real W-key test moves the
commander **32.61 studs at WalkSpeed 32**.

The crocodile's low body was already resting on the ground; requiring its torso
to fall mischaracterized the model. The
[diagnosis](../assets/miniature-ragdoll-crocodile-diagnosis-2026-10-29.json) measures
all four physical legs against the anchored live pose before the first physics
step. They rotate about **0.14–0.41 radians**, with independent rider articulation.
The correction changes the test baseline/animal criterion, not the physics core.

The same normally acquired army later captures its lane's outpost for Sparta.
All source template fingerprints remain unchanged. Mobile/controller clients,
published multiplayer and adverse-network behavior remain separate runtime work.

## Review builds and development gate

The ordinary `build/miniature-mount-refinements-playtest.rbxlx` starts at 200 Coins.
The player-facing `build/miniature-mount-refinements-funded-review.rbxlx` starts
every civilization at 20,000 Coins and omits diagnostic autoruns; it needs no
template-fingerprint setup. Both include all refinements, ragdolls and removed
structure-count ceilings. Press Play in a fresh build; no Rojo Sync is needed.
`build/miniature-playtest.rbxlx` mirrors the ordinary build, and
`build/miniature-all-civs-funded-test.rbxlx` mirrors the funded player review.

Generate a repeatable funded player review with
`npm run build:miniature-game-tests -- --mounts --review`; build its
`.cache/miniature-game-mounted-review.project.json`. For full native diagnostics,
omit `--review` and record the Edit fingerprint before Play as in
[the gameplay guide](../MINIATURE_GAMEPLAY.md).

The complete development gate passes 33 specification items, clean changed-file
Selene/StyLua, seven Node checks, 385 syntax compilations, 244 original logic
cases, 152 miniature logic cases and the immutable eleven-template asset audit.

The [clean review startup](../assets/miniature-refinements-clean-review-startup-2026-10-29.json)
also passes a real Egypt chooser click with 20,000 Coins and zero project
diagnostic autoruns. Every server/shared/client script embedded in the funded
review matches current repository source. The review window is left in Edit;
the user's previous all-civs-funded Play remains running separately.

## Updated close-ups

| Mount | Correction | Screenshot |
| --- | --- | --- |
| Elk | Smaller proportions | [Elk](../assets/miniature-mount-refinements-2026-10-29/elk.jpg) |
| Bear | Slight size reduction | [Bear](../assets/miniature-mount-refinements-2026-10-29/bear.jpg) |
| Lion | Rider seated on the visible back | [Lion](../assets/miniature-mount-refinements-2026-10-29/lion.jpg) |
| Bull | Short, thick block legs/feet | [Bull](../assets/miniature-mount-refinements-2026-10-29/bull.jpg) |
| Crocodile | Splayed foot-sweep gait | [Crocodile](../assets/miniature-mount-refinements-2026-10-29/crocodile.jpg) |
| Wolf | Black eyes | [Wolf](../assets/miniature-mount-refinements-2026-10-29/wolf.jpg) |
| Rhino | Eyes, broad muzzle and nostrils | [Rhino](../assets/miniature-mount-refinements-2026-10-29/rhino.jpg) |

## Engine references

- [BallSocket constraints](https://create.roblox.com/docs/reference/engine/classes/BallSocketConstraint)
- [Collision filtering and groups](https://create.roblox.com/docs/workspace/collisions)
- [NoCollision constraints](https://create.roblox.com/docs/physics/constraints/no-collision)

The user approved stopping the older original-army and mounted-army-funded Plays
to leave one verification slot alongside the current all-civs-funded playtest.
