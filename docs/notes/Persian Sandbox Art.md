# Persian sandbox art evidence

October 29, 2026. Original procedural art for Persia's **550–450 BCE** sandbox
identity. The models are readable game interpretations of Achaemenid material
and architectural vocabulary, not measured reconstructions of nine excavated
buildings. Read with [[Civilization Building and Army Reference]],
[[Miniature Civilization Redesign]] and [[Miniature Economy Implementation]].

## Sources and design decisions

- **Civic terrace and columns:** [UNESCO's Persepolis site account](https://whc.unesco.org/en/list/114/)
  describes the terrace, stair approaches, timber roof construction, slender
  columns and paired bull capitals. The civic model interprets those features
  with a low terrace, three broad steps, a shallow audience portico and four
  paired-head capitals. Its small plan, combined council/trade function and
  abbreviated heads are invented. These monumental features appear only on the
  civic role; ordinary work buildings receive earth roofs and timber lintels.
- **Material evidence:** the excavation institution's
  [Ancient Iran in the ISAC Museum](https://isac.uchicago.edu/publications/ancient-iran-isac-museum)
  distinguishes Persepolis's stone architectural members from mudbrick walls,
  and timber columns in smaller buildings. This supports the kit's material
  separation. Our domestic flat roofs, exposed beam ends and plaster colors
  remain design inferences. They do not reconstruct a particular roof section.
  [Schmidt's primary Persepolis I report](https://isac.uchicago.edu/publications/persepolis-i-structures-reliefs-inscriptions)
  is the follow-up source for measured structures and residential plans.
- **Domestic evidence gap:** excavator Jean Perrot's
  [Suse à la période achéménide, 1985, pp. 67–69](https://www.persee.fr/doc/paleo_0153-9345_1985_num_11_2_4376)
  explicitly identifies major gaps in knowledge of Achaemenid Susa's internal
  layout and domestic architecture. The house, workshop and store are therefore
  modest original courtyard/work compounds using period materials. We do not
  claim that a reconstructed Susa worker's house proves their exact layouts.
- **Limited glazed color:** the [Met's Susa palmette-brick record](https://www.metmuseum.org/art/collection/search/324036)
  documents polychrome palace decoration, with a broader sixth–fourth-century-BCE
  object date. The civic terrace gets seven small blue/ochre accents; their
  position and geometric pattern are invented. The model does not copy the
  palmette or spread royal glazed decoration onto every home and warehouse.
- **Guards and costume:** the [Louvre's Darius-period Susa archer record, SB 3317](https://collections.louvre.fr/ark:/53355/cl010177288)
  dates its robe-clad figure to 522–486 BCE. The [Getty's Susa discussion](https://www.getty.edu/art/exhibitions/persia/explore.html)
  places these guard images within a diverse imperial court style. Long sleeved
  robes, belts, resting bows, quivers and beards are simplified native geometry.
  Their colors and uniform role allocation are artistic choices. The figures
  are not identified as a verified individual or universally uniform “Immortal.”
- **Frontline equipment:** [Herodotus 7.61, translated by A. D. Godley](https://penelope.uchicago.edu/Thayer/E/Roman/Texts/Herodotus/7B%2A.html#61)
  describes Persian caps, sleeved clothing, wicker shields, spears and bows.
  This is an external Greek literary account, not an excavated equipment set.
  Our rectangular shield, upright resting spear and soft cap are abstractions;
  combining them with a court-robe silhouette does not establish campaign dress.

The kit excludes later Islamic domes, minarets and tile-covered mosque forms.
It also excludes Sasanian/Parthian forms and rejects post-Achaemenid reused palace
material as direct evidence for the chosen period. Searches surfaced a
[Seleucid Pasargadae jar](https://www.metmuseum.org/art/collection/search/326386);
its later date means it was **not** used to certify our generic jar shapes.
Specific period ceramic profiles, kiln archaeology and everyday domestic plans
remain research gaps.

## Role manifest

All nine roles use their existing shared catalog footprint, prices, worker slots
and research gates. The Persian kit changes visible structure and props only.
Clay and pottery remain the same explicitly shared recipe budget; the geometry
does not add brick production or additional sale goods.

| Kind / footprint | Distinct visible structure | Evidence and interpretation |
| --- | --- | --- |
| `civic` · 10 × 8 | Raised stone terrace, three broad steps, low rear hall, shallow timber-beamed portico, paired bull capitals and a small trade table | Selective Persepolis monumental vocabulary. Combined function, scale and decoration are invented. |
| `house` · 6 × 6 | Asymmetric L-shaped mudbrick rooms, flat earth roofs with exposed beam ends, private court, low boundary and jar | Period material comparison; domestic room arrangement and roof details are informed interpretations. |
| `farm` · 8 × 8 | Raised cereal furrows divided by a visible irrigation channel | Original readable agriculture role. Exact crop, channel and field layout are not site reconstructions; no functional water simulation. |
| `timber` · 8 × 6 | Partial reed shade, squared beam stock, round logs and an adze bench | Timber use is evidenced; yard plan, timber species, tool and work organization remain interpretive. |
| `material` · 8 × 6 | Low clay bed, mixing trough and nine drying mudbrick props | Mudbrick is evidenced. Extraction layout and drying props are invented; they do not alter the clay ledger. |
| `workshop` · 8 × 6 | Flat-roof side room, separate rectangular firing chamber, firebox and raised vessel shelf | Period materials with original artisan plan. Firing chamber shape and generic pottery need closer period workshop evidence. |
| `storehouse` · 8 × 6 | Taller thick-walled store with four projecting buttresses, a barred entrance and jars | Conservative storage abstraction; buttresses, detached plan and door security are not certified excavated features. |
| `training` · 10 × 8 | Open earth court, small equipment room, three reed targets and spear rack | Bow/spear vocabulary informed by primary literary and museum evidence; target equipment and training layout are inventions. |
| `healer` · 6 × 6 | Small rear room, shaded open court, treatment mat, folded linen and vessel | Explicit gameplay support interpretation. No excavated Persian battlefield hospital or modern medical symbol is implied. |

The shared warm earth palette has restrained civic blue accents. Structural
distinction from Sparta comes from earth/timber flat roofs, asymmetric work
compounds, buttressed storage and the terrace portico. No Spartan building model
or pitched terracotta roof is cloned or recolored.

## Presentation roles and scope

`melee` carries a wicker-style rectangular shield and spear; `ranged` carries a
two-limb resting bow, string and quiver; `medic` carries linen supplies without a
weapon. All wear a long sleeved robe, soft cap and shoes. Their body palette is
fictional art direction and does not represent every historical Persian person.
BodyColors and native body-part colors stay consistent, with the project's
existing warrior face texture. These are original passive figures with anchored,
nonblocking, nonqueryable parts; no Humanoid, Tool, scripts, stats, damage or
healing registration. They do not consume workforce slots or replace the separate
worker renderer. Worker dress still requires its own historical review.

## Implementation and verification boundary

`PersianKit.create(kind)`, `available(kind)` and `createActor(role)` match the
Spartan module boundary. Models are authored at full dimensions, then scaled
once to **0.25** with a fixed local pivot. Every model links this evidence card.
No source rigs, imported meshes or original template assets are edited.

`tests/miniature-game/PersiaScene.server.luau` is a new Studio fixture for the
injected-fake-store test project. It checks every catalog role, four cardinal
rotations, all oriented part corners inside the role footprint, native scale,
inert geometry, actor roles and equipment, consistent body colors, a bounded
part count, selective royal motifs and structural distinction from Sparta. It
creates temporary unparented models and destroys them after the check, without
touching player progression. It reports `PersiaScenePassed/PersiaSceneResult`.

Pinned StyLua and Selene pass for the kit and fixture.

On October 29, 2026, this kit passed its native factory contract checks;
all thirteen culture kits now pass their nine-building/three-actor fixtures.
The separate native UI tour also passed all thirteen actual civilization
switches: culture-specific model previews and three role previews/labels,
owned world rendering at 0.25 scale, a normal-size unarmed commander,
roughly sixteen studs of W-key walking and native farm-click inspection.
Returning to Sparta retained its recorded progression. See the
[native tour evidence](../assets/miniature-kit-tour-native-2026-10-29.json)
and [implementation milestone log](2026-10-29-miniature-implementation.md).

The native gallery overview and role close-up were captured and reviewed;
prototype kit delivery is accepted with the historical limits below.
Historical review is provisional: the consistency review found no
high-confidence period anachronism, but the supported comparisons and
explicit interpretations above do not certify a reconstructed settlement.
Domestic proportions, exact production/storage plans, equipment detail and the historical uncertainties above remain open.
Supplied tending-worker clothing remains provisional. These native
fake-store results do not establish physical-phone, controller,
published-client or live-profile behavior.

### Captured native evidence sheet

The [thirteen-kit evidence gallery](Miniature%20Civilization%20Evidence%20Sheets.md)
now includes this kit's nine-role overview and three-figure close-up. Native
factory contracts and the live selector/preview/walking tour passed. This accepts
the declared prototype kit delivery; the historical interpretation limits above
remain explicit and are not promoted to reconstruction certainty.


## Ranged practice-site addition — October29

The tenth building role is now available through this kit's `ranged` factory.
See [Ranged Training Yards](Ranged%20Training%20Yards.md) for the implemented
structural vocabulary, native contracts and explicit interpretation limits.
The exact training institution, target layout and shelter combination are original
prototype choices, not a newly verified archaeological plan. Existing cited
period/region restrictions and outfit uncertainties still apply. Native checks
passed geometry/scale/footprints/inertness/source preservation; combat and healing
remain separate work.
