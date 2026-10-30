# Civilization building and army reference

October 29, 2026. **All thirteen prototype architecture kits are delivered in the
separate fake-store miniature sandbox. Historical interpretations remain
provisional.** Each kit has nine original quarter-scale building models and
three inert roster figures: 117 buildings and 39 figures in total.

All thirteen existing factions and their established
[period windows](../GAME_VISION.md) remain, as confirmed by the user. Native
factory checks, the all-thirteen selector/preview/walking tour and the captured
gallery review passed for prototype kit delivery. See the
[evidence sheets](Miniature%20Civilization%20Evidence%20Sheets.md),
[native tour record](../assets/miniature-kit-tour-native-2026-10-29.json) and
[implementation log](2026-10-29-miniature-implementation.md).
The production build and original scale preview remain separate.

Read alongside the [redesign rationale](Miniature%20Civilization%20Redesign.md)
and [building-kit contract](../../openspec/changes/miniature-civilization-redesign/specs/civilization-building-kits/spec.md).

## Evidence and interpretation

Sources establish reference forms, sites or surviving traditions. The delivered
miniature designs and their allocation to game roles are original game
interpretations, not reconstructions of a documented farm, barracks or shop at
every site. Each linked culture card records its region, period, observed
features, interpretations, uncertainties and original geometry provenance.
Living traditions, modern reconstructions, earlier comparisons and later
restorations are distinguished from directly dated evidence.

The consistency review found no high-confidence period anachronism. It did not
certify archaeological accuracy: domestic roofs, some work/storage/care plans,
exact military clothing and supplied tending-worker clothing remain qualified
in the individual cards. Native gameplay and gallery checks establish the
prototype delivery, not the historical truth of every design choice.

## Delivered architecture kits

| Faction / period | Delivered structural language | Source card and historical limits |
| --- | --- | --- |
| Sparta · 500–400 BCE | Modest plaster/stone courtyard houses, timber supports and terracotta roofs; a restrained civic portico | [Spartan evidence](Spartan%20Sandbox%20Art.md): Laconian roof vocabulary with qualified Classical domestic comparisons; exact local plans and several production roles remain interpretive. |
| Britain · 1750–1815 | Georgian brick/slate cottage and assembly house, sash openings, commercial warehouse, pottery workshop and regimental yard | [British evidence](British%20Sandbox%20Art.md): dated domestic/commercial and late-Georgian military comparisons; no Victorian factory default. Exact workshop/storage details and uniforms remain qualified. |
| Seneca · 1600–1680 | Curved bark longhouses with timber lashings, Three Sisters mounds, woodland/craft clearings and bark storage shelter | [Seneca evidence](Seneca%20Sandbox%20Art.md): Ganondagan reconstruction and museum/archaeological comparisons; early-contact pottery is qualified against its later decline. No tipi, Norse gable or European masonry kiln. |
| Mongols · 1206–1260 | Household/council/supply gers plus open imperial-settlement crops and a separate settled ceramic craft bay | [Mongol evidence](Mongol%20Sandbox%20Art.md): period travelers and Avraga/Karakorum context are distinguished from continuing ger traditions. Permanent grain/pottery roles do not describe every mobile household. |
| Vikings · 900–1050 | Danish/southern Scandinavian curved-wall timber halls, sloping roof supports, segmented thatch and small daub work sheds | [Viking evidence](Viking%20Sandbox%20Art.md): regional hall/reconstruction and craft comparisons with roof/material uncertainties; no horned helmets or later stave-church/storehouse motifs. |
| Persia · 550–450 BCE | Flat earth-roof courtyard rooms and working yards; terrace, columns and paired-bull motifs confined to the civic hall | [Persian evidence](Persian%20Sandbox%20Art.md): Achaemenid monumental and equipment context; exact domestic/workshop plans remain interpretations. No later Islamic roof vocabulary. |
| Japan · 1550–1600 | Ichijodani timber/plaster town rooms and craft yards, tunnel kiln and raised store; a compressed Matsumoto-inspired civic keep | [Japanese evidence](Japanese%20Sandbox%20Art.md): pre-1573 town and separately dated 1590s keep comparisons; later castle additions excluded. Ordinary buildings are not pagodas. |
| Mauryan India · 320–250 BCE | Timber/earthen rooms, light bowed roof facets, open work compounds and a timber-supported pillared council hall | [Mauryan evidence](Mauryan%20Sandbox%20Art.md): Kumhrar hall/platform evidence with explicit domestic-roof and workshop gaps; no Mughal domes, later Sanchi gateways or Gupta clinic attribution. |
| Spain · 1500–1600 | Plaster/brick patio house with timber upper gallery, tiled craft rooms and a selective civic market arcade | [Spanish evidence](Spanish%20Sandbox%20Art.md): domestic, market and ceramic comparisons distinguish later restorations/buildings. No generic mission or Baroque kit; helmet shape/provenance is qualified. |
| Egypt · 1300–1200 BCE | Mudbrick flat-roof houses, grain bins and shaded working courts; pylons confined to the civic precinct | [Egyptian evidence](Egyptian%20Sandbox%20Art.md): New Kingdom housing and work comparisons, with earlier/partly later sources identified. No pyramid houses or Ptolemaic temple substitution. |
| Rome · 100–180 CE | Ostia-inspired courtyard housing, tile roofs, buttressed raised horreum, civic arcade and barracks court | [Roman evidence](Roman%20Sandbox%20Art.md): selected Hadrianic western-imperial phases; later Housesteads rebuilding excluded. The settlement is an openly composite interpretation. |
| Ottomans · 1520–1566 | Timber/plaster hipped-roof rooms, craft bays and stores; a civic han courtyard with masonry arcade | [Ottoman evidence](Ottoman%20Sandbox%20Art.md): Istanbul/Edirne commercial and domestic vocabulary. This kit has no architectural domes or minarets; exact ordinary construction remains qualified. |
| Ming China · 1400–1600 | Huizhou/Jiangnan skywell houses, stepped firewalls, grey tile roofs and selective civic bracketing | [Ming evidence](Ming%20Sandbox%20Art.md): dated domestic/civic and ceramic comparisons distinguish later changes. No Qing queue or universal royal-yellow roofs. |

## Delivered function-specific buildings

These are the current readable labels in `Shared.Presentation`, not claims that
the exact institution or recipe existed everywhere. The nine roles are civic,
house, farm, timber, material, workshop, storehouse, training and healer. The
civic building includes the merchant function; merchant stalls are not a tenth
purchasable building.

| Faction | Housing | Food / timber / raw material | Artisan production | Store | Training / civic / support |
| --- | --- | --- | --- | --- | --- |
| Sparta | Laconian Courtyard House | Grain Field; Timber Yard; Clay Working Area | Potter's Shed | Store Room | Drill Court; Council Courtyard; Healer Shelter |
| Britain | Worker Cottage | Grain Field; Timber Yard; Clay Yard | Potter's Workshop | Warehouse | Regimental Yard; Assembly House; Infirmary |
| Seneca | Bark Longhouse | Three Sisters Garden; Woodland Work Yard; Clay Working Area | Pottery Work Shelter | Food Store Shelter | Warrior Practice Clearing; Council Longhouse; Healer Shelter |
| Mongols | Family Ger | Grain Plot; Timber Supply Yard; Clay Working Area | Settled Potter's Bay | Supply Ger | Warrior Practice Yard; Council Ger; Treatment Ger |
| Vikings | Household Longhall | Grain Enclosure; Wood Yard; Clay Working Area | Potter's Work Shed | Store Shed | Shield Practice Yard; Council Longhall; Healer Hut |
| Persia | Earth-Roof Courtyard House | Grain Field; Timber Shade Yard; Clay Drying Court | Ceramic Workshop | Buttressed Store | Spear and Bow Court; Terrace Council Hall; Healer Courtyard |
| Japan | Timber Town House | Rice Plot; Timber Craft Yard; Clay Working Yard | Potter's Tunnel Kiln | Raised Store | Training Compound; Council Keep; Treatment House |
| Maurya | Timber and Earthen House | Grain Field; Timber Work Yard; Clay Working Area | Pottery Shed | Store Compound | Warrior Court; Pillared Council Hall; Healer Shelter |
| Spain | Patio House | Grain Plot; Timber Work Yard; Clay Working Yard | Ceramic Workshop | Granary | Pike Drill Yard; Civic Courtyard; Infirmary |
| Egypt | Mudbrick Roof House | Grain Plot; Timber Supply Court; Clay Working Court | Potter's Court | Granary Bins | Drill Court; Pylon Council Precinct; Healer House |
| Rome | Courtyard House | Grain Field; Timber Work Yard; Clay Drying Yard | Potter's Workshop | Horreum | Barracks Court; Civic Arcade; Treatment Room |
| Ottomans | Timber and Plaster House | Grain Plot; Timber Work Yard; Clay Working Yard | Ceramic Craft Bay | Courtyard Store | Infantry Practice Court; Arcaded Council; Treatment Room |
| Ming | Skywell Courtyard House | Rice Plot; Timber Work Yard; Clay Working Yard | Ceramic Workshop | Granary Hall | Spear and Bow Yard; Council Hall; Treatment Room |

### Current shared economy

All thirteen delivered kits use the same authoritative `Catalog` budgets and
four ledgers: Food, Timber, Craft Material and Crafted Goods. Farms depict
grain, rice or Three Sisters crops but all produce Food. Raw Craft Material is
represented as clay, and **every culture currently converts one clay/material
unit into one pottery/crafted unit**; the workshop's base interval is fifteen
active seconds. The base sale prices are 2 Coins for Food, 4 for Timber, 6 for
Craft Material and 15 for Crafted Goods. Culture labels and geometry do not
change prices, output, worker capacity or research gates.

Seneca's craft role is an explicitly qualified early-contact pottery
interpretation; Mongol crop/craft roles represent settled imperial production.
They are not already basket/hide or wool/felt recipes. Timber supply yards do
not imply local forests in every settlement. Worker presentation does not
assert historical labor systems or rank-based worker value. See the
[economy implementation](Miniature%20Economy%20Implementation.md) for the
implemented timing, collection, storage and automation rules.

### Future recipe ideas, not implemented

The original design alternatives remain available for a later economy change:

| Faction / idea | Proposed future interpretation | Required follow-up |
| --- | --- | --- |
| Seneca | Hide-working area; basket/hide artisan lodge | Separate period/community-specific evidence and a documented recipe/balance decision. These do not replace the delivered clay/pottery roles yet. |
| Mongols | Herding enclosure; wool/hide work area; felt-working awning; caravan trade | Research pastoral/craft roles and define goods, recipe, capacity and income rules. No herding, felt production or caravan simulation is implemented. |
| Other culture-specific materials | Additional crafts or resource chains | Preserve or explicitly revise the shared budget through an economy specification and native verification; renamed art alone cannot change income. |

The current original buildings distinguish house, workshop, store, military yard
and civic roles through silhouette and props at quarter scale. Each culture's
[evidence sheet](Miniature%20Civilization%20Evidence%20Sheets.md) contains a
nine-building overview and a three-figure close-up, linked to its source card.

## Delivered passive troop presentations

These are visible roster figures, with current UI labels shown below. All are
original anchored, inert geometry: no combat registration, damage, healing,
firing or mounted movement is supplied by these kits. A healer or medical
attendant is a gameplay support presentation, not a claim of identical
battlefield medical institutions across cultures. The underlying lineup slots
share economic capacity; skins confer no damage or production bonuses.

| Faction | Frontline label and prop | Missile label and prop | Support label |
| --- | --- | --- | --- |
| Sparta | Hoplite — spear and round shield | Slinger — two-cord sling and stone pouch | Healer |
| Britain | Infantry — musket and socket bayonet | Skirmisher — short rifle | Medical Attendant |
| Seneca | Club Warrior — plain wooden club | Archer — bow | Healer |
| Mongols | Dismounted Warrior — curved blade | Archer — recurved bow | Healer |
| Vikings | Axe Warrior — axe and round shield | Archer — self-bow | Healer |
| Persia | Spearman — spear and shield | Archer — bow | Healer |
| Japan | Spear Infantry — yari | Archer — bow | Medical Attendant |
| Maurya | Spearman — spear | Archer — tall bow | Medical Attendant |
| Spain | Pikeman — pike and morion-like helmet | Missile Infantry — crossbow | Medical Attendant |
| Egypt | Axeman — axe and hide-colored shield | Archer — bow | Healer |
| Rome | Legionary — sword and shield | Archer — bow | Medical Attendant |
| Ottomans | Infantry — curved saber | Archer — recurved bow | Medical Attendant |
| Ming | Spearman — spear | Archer — bow | Medical Attendant |

Equipment and clothing are qualified candidates in the culture cards, not
reconstructed complete uniforms. Existing production-game assets are reference
leads, not historical approval; their source originals remain immutable.

### Future troop ideas, not implemented

Later distinct skirmishers, cavalry, mounted archers, lancers, New Kingdom
chariot crews, Mauryan elephants, matchlock/arquebus infantry, artillery,
scouts and pike-shot interactions require their own period evidence, balance
specification and actual miniature movement/combat validation. In particular,
Spanish missile art currently uses a crossbow, Britain distinguishes a redcoat
musket from a green rifle figure, and Sparta uses a sling rather than the
original brief's bow/javelin alternative. No troop candidate implies a
chronological superiority bonus or automatic production-game combat behavior.

## Delivery acceptance and continuing historical review

The delivered prototype kits have recorded region/phase cards, original
function-specific geometry, native factory checks, owned settlement rendering,
actual model/role previews, normal unarmed commander walking and reviewed
native gallery evidence. The linked implementation log owns the detailed
verification record; this matrix summarizes delivered presentation.

Historical review continues for the explicit source gaps and invented
institutions above. Future geometry changes should retain distinct structural
families, function-appropriate decoration, authoritative footprints and
immutable sources. Additional upgrade visuals, new recipes or active military
roles need their own implementation and checks. Thirteen delivered prototype
kits do not mean thirteen historically verified final reconstructions.
