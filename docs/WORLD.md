# World and settlement growth

Eight settlement plots surround one shared battlefield. Players can choose any
available civilization; the terrain belongs to the world rather than reserving
a biome for a particular civilization. Settlement interiors remain protected.

## Space and landscape

The default world is 1,600 × 1,600 studs. Plot centers sit on a 560-stud circle,
and the combat field has a 250-stud radius. Each starter settlement is 60 studs
wide; 49 upgrades add four studs each, finishing at 256 studs wide. The final
square footprints remain separated even when rotated around the circle.
Twenty-eight-stud approach roads lead toward the shared central plaza.

Five biome regions use different ground materials and scenery: open grassland,
woodland, sand and cactus desert, snowy highlands and pines, and muddy wetlands
with reeds. Their boundaries bend across connected irregular ground. Unequal
outer ridges, rolling battlefield slopes and scattered ruined courts break the
earlier radial pattern. A shallow winding river uses twenty connected segments
and three 28-stud dry bridges aligned to the affected approaches. Its water is
decorative geometry above supported ground; swimming is not required.

The combat cylinder is an invisible server boundary. A low stone ring marks its
edge, and landscape ground remains separate from damage rules. Critical roads,
finished plot reservations, barracks exits, spawn areas and floor controls stay
clear of scenery. Battlefield ground stays between 0.15 and six studs high,
with gradients below fifteen degrees; taller relief stays outside the field.
Existing height, ownership and line-of-sight combat checks
still apply. NPCs continue toward their shared central rally; longer travel times
must be measured in play, including wall exits and replacement journeys.

All generated landscape lives under `Workspace.CivilizationPrototype` and moves
with that model. Nothing clears global Terrain or deletes foreign Workspace
objects. Stopping Play removes the generated world as before.

## Asymmetric topography

[Topography](../src/server/Topography.luau) creates deterministic connected
collision surfaces. Coordinate intervals are forty studs near the field and
160 farther out. Shared triangle vertices supply the same height and normal
samples used to place scenery, avoiding floating props and mismatched visible
slopes. Native wedge faces, solid cell fills and boundary skirts form the ground;
small coplanar overlaps seal floating-point seams, including after a world moves
or rotates. This uses ordinary generated parts rather than modifying global
Roblox Terrain.

Plot footprints, full-width roads, the entry, plaza and crossing reservations
flatten intersecting triangles before construction. Gentle transitions lead
into taller land. Biome boundaries and landforms use fixed noise and unequal
offsets, while scenery and cover use a fixed seed. A fresh world has the same
terrain instead of rearranging geography when players switch civilizations.

The complete landscape currently measures **1,929 static BaseParts**, below its
2,000-part limit. That includes terrain collision, vegetation, water, bridges
and cover. Part counts are geometry measurements, not frame-rate guarantees.

The terrain accounts for 1,472 of those parts. A ten-stud sampling scan measured
a highest battlefield point of approximately 3.93 studs and an outer ridge point
of 46.72 studs; the six-stud field bound remains the design limit. A real NPC
walked forty horizontal studs uphill, gaining about 3.61 studs in 3.68 seconds,
then returned downhill in 5.18 seconds while remaining supported and eligible
for battlefield combat. These are single-window engine measurements.

## Inspected terrain

These October 14 captures show one claimed completed settlement and seven
unclaimed starter plots. Inspection-only settings removed local fog, used a
14:00 clock and temporarily kept the generated world streamed in for the
overview. Normal play retains its usual lighting and streaming settings.

![Asymmetric terrain, irregular biome boundaries and winding river](assets/topography/overview.png)

![Unequal outer snowy ridges with grounded vegetation](assets/topography/ridge.png)

![Winding shallow river and road-aligned dry crossings](assets/topography/river.png)

![Gentle battlefield slopes with supported paths and cover](assets/topography/battlefield-slope.png)

## Fifty gradual settlement levels

Every accepted upgrade adds a lasting feature and a four-stud strip of land.
Early additions include a barracks at level two, a dwelling, storehouse, garden,
workshop, orchard and craft hall. Later levels add district buildings, avenues,
carvings and larger ceremonial structures. Consecutive growth retains existing
geometry; switching civilization or rebuilding a transformed plot reconstructs
the same unlocked features deterministically.

| Milestone | Added detail |
| --- | --- |
| 10 | Civilization-themed civic monument |
| 20 | Ceremonial entrance and growing perimeter |
| 30 | Grand hall with incorporated civilization/owner identity |
| 40 | Ceremonial wings |
| 50 | Final ceremonial monuments completing the settlement |

The architecture follows each civilization: Spartan sanctuaries, Georgian brick
avenues, Seneca longhouses and council village, Mongol yurts and khan's pavilion,
Norse carved halls, Persian palace terraces, Sengoku castle courts, Mauryan stupa
precincts, Spanish arcades, Egyptian pylon temples, Roman civic basilicas, Ottoman
domed courtyards and Ming palace courts. These are stylized generated references,
not complete historical reconstructions. Egyptian growth uses the chosen New
Kingdom temple reference rather than adding a pyramid as its default landmark.

The forecourt remains usable throughout growth. Initial weapon/armor tier pads
retire when purchased; the tier-four pads remain stable and offer later tiers
through 50, preserving one purchase per touch entry. The barracks retains its
four-level progression and two-troop maximum. See [economy](ECONOMY.md) and
[army rules](ARMY.md).

## Configuration and saved progress

[ProgressionConfig](../src/shared/ProgressionConfig.luau) controls the current
50-level cap, initial width, width increment, stat endpoints and price increments.
[WorldConfig](../src/shared/WorldConfig.luau) derives final footprint reservations,
plot radius, ground extent and combat radius from the progression, so increasing
the cap cannot silently overlap plots. Future cap changes still need new art,
route, economy and performance verification.

Existing saves keep their coins and numeric levels. A previously saved level
four becomes level four on the new visual and combat curve; it is not reset or
automatically granted level 50. Profile keys, scopes and schema stay unchanged.
The normal game restores each civilization independently. See
[saved profiles](PROFILES.md).

## Verification boundaries

Module checks verify all 13 civilizations at every level, retained features,
structural bounds, forecourt/barracks exits, transformed rebuilds, independent
upgrade caps, final plot separation and generated-world cleanup. Maximum
settlements measured 203–272 static BaseParts each. Before the topography change,
one eight-capital geometry fixture contained 2,466 BaseParts, including 423
landscape parts. Those earlier counts and captures below describe the previous
flat landscape, not the new terrain or an eight-player performance test.

Actual navigation, native purchases, visual inspections, saved restoration and
hardware/public-client limitations are recorded in [playtest evidence](PLAYTEST.md).

## Earlier growth illustrations

These earlier October 14 Studio captures use generated geometry and inspection cameras.
The overview contains one claimed plot and seven static visual fixtures, with
local fog removed and a 14:00 clock for visibility. It is not an eight-client test.

![Eight completed settlements around the biome battlefield](assets/world-growth/overview.png)

The same camera compares Britain's level 1, 25 and 50 footprints: 60, 156 and
256 studs. The starter manor remains while districts, perimeter and grand hall
appear. These are static builder illustrations, separate from the native
upgrade and saved-restoration checks.

| Level 1 | Level 25 | Level 50 |
| --- | --- | --- |
| ![Britain starter](assets/world-growth/britain-01.png) | ![Britain middle settlement](assets/world-growth/britain-25.png) | ![Britain finished settlement](assets/world-growth/britain-50.png) |

![Dry battlefield bridge, low cover and distant civilization landmarks](assets/world-growth/crossing.png)

Imported melee models entered the arena after approximately 25–29 seconds from
levels 2/25/50. Separate ranged fixtures walked from levels 25 and 50 to points
inside the field in about 28.6 seconds and verified actual projectile impacts.
The latter use simulated owner identities; neither those timings nor the
overview prove connected multi-owner combat or hardware frame rates.
