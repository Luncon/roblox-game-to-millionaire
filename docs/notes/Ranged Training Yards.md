# Ranged training yards — tenth building role

October29,2026. Each of the13kits now has an original ranged practice-site model
in addition to the previous nine building roles. All ten roles passed native
factory checks, and the extra13ranged models passed distinct-geometry, cardinal
footprint, quarter-scale, inertness and immutable-template checks. See the
[native server evidence](../assets/miniature-simple-shop-server-2026-10-29.json).

These are game interpretations using each kit's already cited period/material
vocabulary. They are not excavated barracks reconstructions. Practice targets,
shooting lines, exact institutions/layouts and roof combinations are readability
inventions or uncertain extrapolations. The source cards below retain their
specific region/period exclusions and citations. Existing missile role props
remain unchanged; a ranged building need not mean archery for every faction.

| Civilization | Model features observed in the implementation | Sources and remaining limits |
| --- | --- | --- |
| Sparta | Low tile shade, rear plaster screen and sling-stone tray | [Spartan source card](Spartan%20Sandbox%20Art.md) |
| Rome | Brick store, piers and shallow tiled gable | [Roman source card](Roman%20Sandbox%20Art.md) |
| Persia | Earth backstop, exposed beams and flat cover | [Persian source card](Persian%20Sandbox%20Art.md) |
| Egypt | Mudbrick screens, buttresses and linen shade | [Egyptian source card](Egyptian%20Sandbox%20Art.md) |
| Maurya | Timber supports and a bowed reed cover | [Mauryan source card](Mauryan%20Sandbox%20Art.md) |
| Seneca | Bent-sapling bark cover, fiber lashings and boundary logs | [Seneca source card](Seneca%20Sandbox%20Art.md) |
| Vikings | Segmented thatch shelter and timber windbreaks | [Viking source card](Viking%20Sandbox%20Art.md) |
| Mongols | Circular felt windbreak and portable rope posts | [Mongol source card](Mongol%20Sandbox%20Art.md) |
| Japan | Board rear wall, shingle shade and raised shooting line | [Japanese source card](Japanese%20Sandbox%20Art.md) |
| Ming | Grey-brick rear wall, hipped roof and stepped screens | [Ming source card](Ming%20Sandbox%20Art.md) |
| Ottomans | Masonry storage bay, tiled hip and side seat | [Ottoman source card](Ottoman%20Sandbox%20Art.md) |
| Spain | Brick side bay, tiled lean roof and crossbow-rest bench | [Spanish source card](Spanish%20Sandbox%20Art.md) |
| Britain | Brick equipment bay, slate lean roof and shooting pegs | [British source card](British%20Sandbox%20Art.md) |

The original geometry is in `prototypes/miniature/game/server/ArcheryRanges.luau`;
every kit delegates its `ranged` factory entry there. Its10×8footprint shares the
same price and function budgets across cultures. World provides two automatic
ranged figures when the fixed ten-troop total has room. No research, ranged damage,
new weapon behavior or civilization bonus is implied by this prototype art.

The older26gallery images show the original117building/39role candidates. This
addition raises the current building-role catalog to130models across thirteen
civilizations; those historical gallery images have not been relabeled as if
they pictured this tenth role.
