---
tags: [roblox, miniature, egypt, historical-art]
updated: 2026-10-29
---

# Egyptian sandbox art evidence

Original native geometry for **New Kingdom Egypt, about 1300–1200 BCE**. This is a readable game kit, not a reconstruction of one excavated town. Mudbrick, flat roofs, grain bins, working courts and linen distinguish it from Sparta's tiled roofs and Persian terraces. Pylons appear only in the civic landmark. Ordinary homes are never pyramids or miniature temples.

Read with [[Civilization Building and Army Reference]], [[Miniature Civilization Redesign]] and the approved `miniature-civilization-redesign` change. Source cards were checked October 29, 2026. No museum photograph, texture, model or inscription is imported; all geometry and colors are original abstractions.

## Period source cards

| Card | Primary source and date | What it supports | Boundary applied to this kit |
| --- | --- | --- | --- |
| E1 · Domestic | University of Memphis, [Deir el-Medina](https://www.memphis.edu/egypt/resources/colortour/westbank5.php), principally Dynasties 19–20 | Compact housing, shared walls, stone foundations and usable flat roofs | Our detached catalog footprint, outer court and small roof stair are invented. The **Ptolemaic temple** visible on the same page is later and is excluded. This workmen's village is not a universal plan for Egyptian households. |
| E2 · Civic | University of Memphis Karnak field project, [Second Pylon](https://www.memphis.edu/hypostyle/tour_hall/second_pylon.php), Horemheb and Ramesses I, around 1304 BCE | A massive two-part gateway and court vocabulary near the selected period | A sacred monumental form becomes one restrained civic landmark for game readability. A council office and exchange counter are invented functions; ordinary shops/houses receive no pylons, royal reliefs or obelisks. The stepped batter and cornice are coarse geometric approximations. |
| E3 · Agriculture | The Met, [Ramesside sickle insert, 09.180.2029](https://www.metmuseum.org/art/collection/search/568323), about 1300–1080 BCE | Cereal cultivation and flint-in-wood harvesting technology within the period | The standing grain bed, channel, spacing and basket are invented arrangements. There is no modern metal harvesting machine or field of pyramid houses. This object supports agricultural technology, not our irrigation plan. |
| E4 · Timber | The Met Egyptian Expedition, [Carpenters at Work, TT100, 35.101.1](https://www.metmuseum.org/art/collection/search/544639), facsimile of an original dated about 1479–1396 BCE | Earlier New Kingdom woodworking and workshop activity | Timber supply court, log stack, sawn plank and trestle bench are game interpretations. The image is earlier than 1300–1200 BCE and is a tomb scene, not a measured workshop plan; continuity into the kit period is an inference. |
| E5 · Clay | The Met Egyptian Expedition, [Brickmakers Getting Water, TT100, 30.4.89](https://www.metmuseum.org/art/collection/search/544648), facsimile of an original about 1479–1425 BCE | Earlier New Kingdom use of water and mud in brick production | Wet clay basin, drying bricks and mould distinguish this production court. Exact tools, dimensions and economic recipe are invented. This earlier example does not establish our pit layout or a Ramesside labor institution. |
| E6 · Pottery | UCL Digital Egypt, [pottery kilns](https://www.ucl.ac.uk/museums-static/digitalegypt/pottery/kilns.html), technical reference with earlier excavated examples; The Met, [wheel-made marl-clay jug, 16.10.426](https://www.metmuseum.org/art/collection/search/547032), about 1550–1458 BCE | Distinct fire hole/firing chamber vocabulary and wheel-made New Kingdom ceramics | Our visible wheel, domed kiln, shed and vessels are original simplifications. UCL's illustrated earlier kilns and the early Dynasty 18 jug are comparative evidence, **not** a verified 19th-Dynasty kiln reconstruction. Pottery is the game's generic crafted output. |
| E7 · Storage | Neal Spencer/British Museum, [Amara West neighborhood excavation report](https://isac.uchicago.edu/sites/default/files/uploads/shared/docs/ois10.pdf), chapter 8, town founded around 1300 BCE; British Museum, [farming and Amara West storage interpretation](https://artsandculture.google.com/story/farming-in-the-nile-valley-the-british-museum/kAWxk-YaOyfgJw?hl=en) | Ramesside settlement storage and large clay food containers; the museum's pictured house bin is about 1200–1070 BCE | Amara West is an Egyptian colonial foundation in **Upper Nubia**, not a neutral example of all Egypt. The pictured bin is partly later than our target. Paired tall bins, domed caps, draw hatches and accounting table are a readable inference, not an excavated bin elevation. Middle Kingdom funerary granary models were not relabeled as New Kingdom evidence. |
| E8 · Clothing | Museo Egizio, [Kha's linen tunic, S.8530](https://collezioni.museoegizio.it/en-GB/material/S_8530/), about 1425–1353 BCE; UCL, [dress](https://www.ucl.ac.uk/museums-static/digitalegypt/textil/dress.html) | New Kingdom linen and broad tunic/wrapped-garment vocabulary | Plain kilts, simple short hair, sandals, support tunic and blue sash are original readability choices. These sources do not establish a uniform worn by all soldiers or healers. No royal nemes, crown or ornamental collar is applied to ordinary recruits. |
| E9 · Infantry | The Met, [Battle Ax of Baki, 35.3.56](https://www.metmuseum.org/art/collection/search/548308), about 1504–1447 BCE; Grand Egyptian Museum, [model shield of Nakhti](https://gem.eg/en/collection/artefacts/model-shield-of-nakhti), Dynasty 12 | Earlier New Kingdom copper-alloy axe vocabulary; explicitly **Middle Kingdom** hide-over-wood shield comparison | Axe infantry is an original candidate. Blade, handle and small rounded hide shield are abstractions. The axe handle and lashing have modern restorations, and the shield is earlier comparative evidence; neither proves an exact 19th-Dynasty infantry uniform. No Greek hoplite helmet, cuirass, greaves or round bronze shield is substituted. |
| E10 · Archer | Staatliche Museen zu Berlin, [composite bow ÄM 4712](https://search.smb.museum/object/obj-606695), Dynasty 19, Thebes-West | Period bow construction and archery vocabulary | The low-detail two-limb bow, string and quiver suggest an archer without reproducing this museum bow's construction. The museum associates composite bows with elite access; our generic display role does not claim every soldier used one. No crossbow, firearm or mounted unit is implemented. |
| E11 · Care | Anne Austin's original [textual/osteological study of health care at Deir el-Medina](https://escholarship.org/uc/item/4rw1m0cz), UCLA, 2014 | Archaeological/textual study of health care in the relevant workmen's settlement | The separate treatment room, shaded couch, linen package and dedicated unarmed support actor are gameplay inventions. No claim of a reconstructed army hospital, standardized medic uniform or demonstrated battlefield organization is made. There is no modern cross, combat or healing behavior. |

## Complete role manifest

All nine roles use the same authoritative catalog footprint as the other kits. Models are authored at full dimensions, scaled exactly once to **0.25**, and contain anchored, noncolliding, nontouching, nonqueryable parts. They contain no Humanoid, Tool, executable script, production logic or saved state.

| Kind · footprint in studs | Egyptian silhouette | Source cards / invention limits |
| --- | --- | --- |
| `civic` · 10 × 8 | Low rear flat-roof office, open exchange shade, paired battered pylon gateway and low precinct wall | E1/E2. Pylon confined here; council/merchant combination and scale invented. |
| `house` · 6 × 6 | Mudbrick body, pale flat roof and parapet, visible roof stair, small working court and jar | E1/E8. Detached arrangement is a game choice; no Ptolemaic temple details. |
| `farm` · 8 × 8 | Dark silt bed, grain ears, narrow water channel and harvest basket | E3. Permanent ripe crop and channel plan invented. |
| `timber` · 8 × 6 | Open log stack, plank, shaded carpenter's bench and low mudbrick wall | E4. Supply yard avoids a Greek pitched shed or implied local forest abundance. |
| `material` · 8 × 6 | Wet clay basin, low earth banks, drying bricks and mould | E5. Pit and drying court are abstractions; the unchanged game's material balance is independent of the visible bricks. |
| `workshop` · 8 × 6 | Flat-roof potter's room, exposed wheel, low firing chamber/fire hole and plain jars | E1/E6. Kiln elevation and production layout remain interpretive. |
| `storehouse` · 8 × 6 | Two tall grain bins with small filling mouths/draw hatches, low enclosing wall and accounting table | E7. Bin elevations are invented; the gameplay capacity applies to all collected goods. |
| `training` · 10 × 8 | Open sand court, reed shade, plain woven practice screens and timber rack | E8–E10 provide equipment context; screens, rack and exact drill-court institution are invented readability props. No Greek columns. |
| `healer` · 6 × 6 | Small flat-roof treatment room, shaded linen couch, folded cloth and jar | E1/E8/E11. Dedicated building and institution are gameplay abstractions. |

The three roster figures remain cosmetic. `melee` has a copper-colored axe and small hide shield, `ranged` has a bow/string/quiver, and `medic` has a linen tunic, satchel and folded cloth without a weapon. All use the existing Egyptian NPC art skin default and established warrior face consistently; this is a game palette, not a statement about every historical Egyptian person. No source rig or outfit model is modified. Imported tending-worker costume remains provisional wherever the existing worker renderer is used.

## Verification boundary

`EgyptianKit.luau` matches the existing `available(kind)`, `create(kind)` and `createActor(role)` interfaces. The native `tests/miniature-game/EgyptScene.server.luau` fixture covers all nine roles, the 36 cardinal footprint checks, three actor silhouettes, exact scale, consistent body/face defaults, inertness, and limits pylons to the civic role. It compares the domestic silhouette with the existing Spartan kit. Its temporary models are destroyed and no player data is accessed.

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
Earlier comparative sources, invented kiln/bin elevations, exact clothing and the dedicated training/medical institutions remain qualified as above.
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
