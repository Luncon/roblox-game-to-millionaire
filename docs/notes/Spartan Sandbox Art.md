# Spartan sandbox art evidence

October 29, 2026. Original procedural art for the separate fake-store miniature
sandbox. These are readable game designs for Sparta around 500–400 BCE, not
reconstructions of identified buildings. The other twelve identities remain
available; their miniature art is explicitly unavailable until their own kits
are reviewed. A Spartan model is never substituted for another civilization.

Read with the [civilization reference matrix](Civilization%20Building%20and%20Army%20Reference.md)
and [redesign proposal](../../openspec/changes/miniature-civilization-redesign/proposal.md).

## Evidence and limits

- **Laconian roofs:** Nancy A. Winter's [regional terracotta study, pp. 13–18](https://www.ascsa.edu.gr/uploads/media/hesperia/148121.pdf)
  documents curved pan/cover elements from Artemis Orthia at Sparta, and cautions
  against treating every regional decoration as Spartan. The kit uses rounded
  cover seams and restrained ridges; its continuous slabs simplify the pan tiles.
  Roof pitch, spacing and dimensions are invented. Temple akroteria and sacred
  sculpture are not applied to ordinary homes or workshops.
- **Domestic comparison:** the [Acropolis Museum's House Θ](https://www.emfc.gr/en/node/16452)
  has a small inner courtyard and surviving Classical phases, with a later
  third-century-BCE workshop conversion. It supports a comparative Greek court
  vocabulary, not an excavated Spartan plan. The kit does not copy the later
  workshop installation or imply a documented Spartan residence.
- **Spartan civic context:** [Hellenic Heritage's Sparta site summary](https://www.hh.gr/en/destinations/acropolis-of-ancient-sparta/)
  identifies public/private remains and an Archaic stoa among a much broader
  chronological assemblage. The modest open-sided civic arrangement is a design
  inference. Roman theatre, second-century-CE stoa and Byzantine forms are excluded.
- **Ceramic vocabulary:** the [Louvre's Laconian hydria record](https://collections.louvre.fr/en/ark%3A/53355/cl010285272)
  supplies a regional vessel comparison and conservation limits. Our small
  unpainted rounded props are original abstractions, not a copy of this object's
  shape, decoration or restored parts. The kiln and production recipe remain
  inventions rather than a reconstructed Laconian workshop.
- **Training comparison:** an [Athenian palaestra scene dated about 470 BCE](https://olympicgames.culture.gov.gr/en/ideodi/kalos_kai_agathos/gimnasia/5_AttikosKratiras.html)
  depicts supervised exercise, javelins and a column. Our uncluttered court
  borrows the idea of an exercise area; wooden targets and the exact rack are
  readability props, not documented Spartan military training equipment.

## Role cards and manifest

Every role has original anchored, nonblocking native geometry and the same
catalog footprint used by authoritative placement. Width/depth below include
roof overhang and all props. The common warm cream, clay and timber palette is
an artistic choice, not a claim that surviving ancient buildings looked uniform.

| Kind / footprint in studs | Distinct geometry | Evidence used / remaining uncertainty |
| --- | --- | --- |
| `civic` · 10 × 8 | Broad rear hall, low wings, timber portico, open trade counter and fabric awning | Spartan civic context and Laconian roof study; combined council/merchant function, plan and canopy are invented. Columns are confined to restrained civic supports. |
| `house` · 6 × 6 | Low rear roof, modest stone base, enclosing court walls, paving and vessel | Comparative Classical House Θ and Laconian roof vocabulary; precise Spartan domestic wall treatment, plan and four-worker housing budget are interpretations. |
| `farm` · 8 × 8 | Open rectangular soil bed, grain rows and low timber margins | Agricultural role from the agreed game brief; crop spacing, enclosure and permanent visible grain are inventions. A dedicated Classical Laconian cultivation source remains outstanding. |
| `timber` · 8 × 6 | Open stacked round logs and workbench; no house roof | Gameplay supply-yard role; log species, stack construction and bench are unsourced abstractions. No claim that all timber was locally grown. |
| `material` · 8 × 6 | Low clay bed, side banks and clay vessels | Laconian ceramic comparison supports a clay vocabulary, not this extraction layout. Pit and stock handling need site-specific evidence. |
| `workshop` · 8 × 6 | Small roofed shed, exposed domed kiln and pottery bench | Roof study plus Laconian vessel comparison; exact kiln form, tools and shed arrangement remain interpretive and need workshop archaeology. |
| `storehouse` · 8 × 6 | Taller enclosed store, raised stone floor, braced door and jars | Comparative domestic storage vocabulary and roof study; raised floor and detached plan are gameplay readability choices, not a documented Spartan granary. |
| `training` · 10 × 8 | Open sand court, three practice targets and rack | Period Athenian training comparison; no claim of an excavated Spartan drill court or automatic troop/combat implementation. |
| `healer` · 6 × 6 | Four-post linen shade, treatment couch and vessel | Gameplay support shelter with common kit materials. Exact form and Spartan battlefield institution are unverified; it confers no healing behavior here. |

## Scale, actors and verification

Models are authored at full dimensions then scaled once to **0.25**, keeping
catalog footprints authoritative. Eight 40 × 32 plots sit around a 110-stud ring
on a 400-stud ground. Their four-stud crossing lanes remain open to the normal
size unarmed commander. Invisible selection proxies provide click and nearby
inspect targets without adding collision. Merchant thumbnails use the same
actual models, without those interactions.

Two initial tending workers use sanitized temporary clones of the supplied R15
farmer and existing pure `FarmTenders.prepare/pose` helpers. Source rigs, clothing
and headwear stay immutable. Every rendered body part is anchored, nonqueryable
and nonblocking. A fresh disabled Humanoid renders classic clothing only; no
production bootstrap, combat registration, pathfinding or live profile access
is imported. The supplied farmer's dress is provisional and **not historically
reviewed Spartan clothing**.

The selected Spartan roster now has three distinct **presentation-only** figures:

| Roster role | Visible design | Historical scope |
| --- | --- | --- |
| `melee` | Spear, round bronze-colored shield, simplified cuirass, greaves and cheek-guard helmet | The [Met's sixth–fifth-century-BCE Corinthian-type helmet](https://www.metmuseum.org/art/collection/search/250921) supports the broad Greek hoplite equipment vocabulary. Geometry and proportions are original abstractions; this is not a reconstructed individual Spartan panoply. There is no claim of a single uniform worn by all Spartans. |
| `ranged` | Short earth-colored tunic, stone pouch and loose two-cord hand sling | [Xenophon's Anabasis 3.3](https://fgh.perseids.org/read/greekLit/tlg0032/tlg006/perseus-eng2/3.3.13-3.4.1) describes Rhodian slingers in the Greek army of 401 BCE. It supports a near-period Greek support candidate, not evidence that Rhodians were Spartan citizens or that every Spartan force had this roster. The costume and resting sling pose are interpretive. No modern forked slingshot is used. |
| `medic` | Pale tunic, linen satchel and folded bandage; no weapon | A gameplay support candidate. The attire, satchel and permanent specialist role are interpretive and await specific Classical Laconian medical evidence. No modern cross insignia or automatic healing is implied. |

These original native figures have no Humanoid, Tool, scripts, combat registration
or attack/healing stats. All parts are anchored, noncolliding and nonqueryable;
their cloth uses colored geometry. Selected fighters stand within the purchased
training court, and the selected support figure within the healer footprint,
following relocation/cardinal rotation. Roster changes retain matching existing
figures and never consume workers. The existing Spartan NPC art skin default and
warrior face are maintained consistently; the palette is fictional art direction,
not a population-wide historical assertion. Original source models are untouched.

`tests/miniature-game/Scene.server.luau` checks native footprint bounds for all
nine thumbnails, starter geometry, four housing places, two moving workers,
normal unarmed commander, retained building instances and an Edit-mode source
fingerprint. The generated test project must map `TemplateFingerprint` and record
`ReplicatedStorage.OriginalSandboxTemplates` before Play. Select Sparta within
60 seconds and leave the starter layout/workforce unchanged for its 14-second
observation. This fixture does not access player DataStores.

The fixture also creates an unparented legal test settlement, independently of
the player's state: four fighters plus one support, all three equipment
silhouettes, correct building association and cardinal rotation, scale/footprint,
retained actor instances, roster reduction/unpacking and worker independence.
It verifies an unknown civilization stays empty rather than receiving Spartan art,
then destroys the temporary models before comparing source fingerprints.

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
Robe/equipment research, full curved pan tiles and the role-specific archaeological gaps above remain open.
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
