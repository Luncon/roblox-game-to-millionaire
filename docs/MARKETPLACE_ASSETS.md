# Civilization outfit and weapon sources

The prototype uses 13 normalized outfit templates and 19 equipment templates.
Five outfits derive from the user's existing melee skins. The remaining outfits
use selected Creator Store clothing and cosmetics; eleven equipment templates
also came from the user's Studio additions. These are approximate historical
looks, with practical substitutions for the existing R6 troops and R15 players.

Studio's native Creator Store search verified the selected Model listings on
October 14, 2026 using the free-price filter: `isFree=true`, `priceCents=0`.
This records their import-time status; listings can change. No paid avatar
catalog purchases were made.

## Outfit provenance

| Civilization | Source | Included appearance |
| --- | --- | --- |
| Sparta | User's `GiraffeStrange` melee skin | Derived clothing and cosmetics; existing mapped Spartan helmet takes precedence on players/generated troops · [Studio view](assets/outfits/sparta.png) |
| Britain | User's `little british dude` melee skin | Derived redcoat clothing; existing mapped tricorn takes precedence · [Studio view](assets/outfits/britain.png) |
| Seneca | User's `Models.Native` inner character | Derived clothing; existing mapped headdress takes precedence · [Studio view](assets/outfits/seneca.png) |
| Japan | User's `Ninja` melee skin | Derived clothing and available head cosmetics · [Studio view](assets/outfits/japan.png) |
| Mauryan India | User's `Indian Guy` melee skin; [White Turban, 247070867](https://create.roblox.com/store/asset/247070867), @AlcatrazDweller | Derived clothing and turban for players/generated ranged troops; custom melee headwear is retained without an added hat · [Studio view](assets/outfits/maurya.png) |
| Mongols | [Mongolian Lancer, 9332608039](https://create.roblox.com/store/asset/9332608039), @012alpha | Clothing and helmet; horse excluded · [Studio view](assets/outfits/mongols.png) |
| Vikings | [Viking Soldier, 8377555069](https://create.roblox.com/store/asset/8377555069), @RyGuySoldier | R15 source garments and outer Crown of Warlords helmet; adapted onto existing rigs · [Studio view](assets/outfits/vikings.png) |
| Persia | [Persian Soldier, 204073479](https://create.roblox.com/store/asset/204073479), @Solement; [White Turban, 247070867](https://create.roblox.com/store/asset/247070867), @AlcatrazDweller | Red/gold shirt `28562127`, pants `28562145` and turban for players/generated troops · [Studio view](assets/outfits/persia.png) |
| Spain | [Conquistadores, 12779200695](https://create.roblox.com/store/asset/12779200695), @Captain_VulcanII; [Conquistador Helmet, 44430544](https://create.roblox.com/store/asset/44430544), @ScriptReviewer | Variant 8 matching brown shirt/pants and separate helmet · [Studio view](assets/outfits/spain.png) |
| Rome | [Roman Soldier #, 8559720356](https://create.roblox.com/store/asset/8559720356), @TechnoleKI | Clothing and four helmet cosmetic parts; gladius exported separately · [Studio view](assets/outfits/rome.png) |
| Ottomans | [Persian Soldier uniform, 204073479](https://create.roblox.com/store/asset/204073479), @Solement; [Janissary Hat, 10607813533](https://create.roblox.com/store/asset/10607813533), @AlpArslan_Seljuk | Reused red/gold uniform with distinct Janissary headwear; a stylized substitute · [Studio view](assets/outfits/ottomans.png) |
| Ming China | [Clothing and hat source, 793198106](https://create.roblox.com/store/asset/793198106), @Def319 | Shirt, pants and hat only; baked weapons and armor pieces excluded · [Studio view](assets/outfits/ming.png) |
| Ancient Egypt | [Uniform source, 9283778110](https://create.roblox.com/store/asset/9283778110), @CIocksmith | Uniform with existing Pharaoh headwear for players and Anubis headwear for generated troops · [Studio view](assets/outfits/egypt.png) |

The modern Persian candidate `11877931865` and the earlier Ottoman blue-pants
candidate `4529179679` were rejected. They are not exported outfit sources.
The original five custom melee skins retain their own clothing and headwear;
the derived outfit copies dress players and generated troops without modifying
those originals.

## Additional weapon provenance

These eight exports extend the eleven user-provided equipment models documented
in [the asset catalog](../assets/README.md#imported-equipment-visuals).

| Template | Creator Store source | Equipped roles |
| --- | --- | --- |
| `axe` | [10747426648](https://create.roblox.com/store/asset/10747426648), @DalpixReBirth | Seneca melee; Viking players and both troop classes |
| `scimitar` | [5325022567](https://create.roblox.com/store/asset/5325022567), @Pseudosuper | Mongol, Ottoman and Ming players/melee troops |
| `gladius` | [8559720356](https://create.roblox.com/store/asset/8559720356), @TechnoleKI | Roman players/melee troops |
| `rapier` | [9206690275](https://create.roblox.com/store/asset/9206690275), @oltcheron | Spanish players/melee troops |
| `khopesh` | [9377676825](https://create.roblox.com/store/asset/9377676825), @stormvict | Egyptian players/melee troops |
| `musket` | [16819224717](https://create.roblox.com/store/asset/16819224717), @EndlessPossibiliti | British and Ottoman ranged troops |
| `crossbow` | [4842204072](https://create.roblox.com/store/asset/4842204072), Roblox | Spanish and Ming ranged troops |
| `slingshot` | [47620](https://create.roblox.com/store/asset/47620), Roblox | Egyptian ranged sling role; stylized visual substitute |

## Export and runtime boundaries

Only inert visual data is exported. Imported controllers, scripts, source
Humanoids, tools, forces and old joints do not run in the game. Temporary source
folders are removed before Play. Original user-provided Workspace models remain
unchanged. Repository binaries map through Rojo into `ServerStorage`; the game
does not fetch or insert marketplace models during play.

Outfit templates contain optional classic clothing, an optional body-color
preset and normalized body cosmetics with a `Handle`, `BodyPart`, `BodyOffset`
and `ReferenceSize`. Runtime clones are sanitized again. R6 body anchors map to
R15 upper torso/arm/leg segments; offsets scale to the target body and mesh
assemblies retain their proportions. These rigid cosmetics are approximate
fits, especially around R15 limb joints.

Outfits replace the visible uniform while preserving avatar clothing instances.
Clearing restores affected clothing and body-color fields when they still match
the outfit's last write. Later external wardrobe edits become the restore
baseline; destroyed originals are never recreated. Late native avatar
appearance loading forces a fresh outfit application without discarding that
baseline. Unrelated avatar items and custom melee clothing/headwear are retained.

TroopAppearance separately gives every live melee/ranged clone a civilization
skin-tone art default and warrior face texture `10526794`, reused from the
user's Seneca expression. This also applies to custom melee clones while keeping
their meshes, proportions, clothes and headwear. NPC BodyColors and body-part
colors match. Original source models and their faces remain untouched; player
avatars do not receive this NPC override. The thirteen palettes are art defaults,
not claims that historical populations shared one skin tone. Skin baked into
uniform textures remains part of those original textures.

Every weapon role has a mapped imported visual. Missing or invalid templates
retain procedural fallback. Source appearance never supplies damage, health,
ownership or cooldowns: the existing server upgrade and combat rules still
apply. See [army behavior](ARMY.md) and [playtest evidence](PLAYTEST.md) for
runtime scope and recorded limitations.

## Studio outfit views

Current NPC palette and warrior-face views:
[Britain](assets/outfits/britain-warrior-palette.png),
[Seneca](assets/outfits/seneca-warrior-palette.png) and
[Maurya](assets/outfits/maurya-warrior-palette.png).
These show both troop classes using their civilization's tint and the shared
warrior expression, alongside a player whose avatar face is unchanged. Tune
the art defaults in [TroopAppearance](../src/server/TroopAppearance.luau).

The initial thirteen outfit previews linked above predate the rounded generated head
correction. Rounded-head milestone views: [Vikings](assets/outfits/vikings-rounded-heads.png),
[Maurya](assets/outfits/maurya-rounded-heads.png) and
[Ottomans](assets/outfits/ottomans-rounded-heads.png). Generated troops use
Roblox's [built-in Head mesh](https://create.roblox.com/docs/reference/engine/enums/MeshType)
while custom melee heads retain their original meshes. All these captures
predate the subsequent NPC skin-tone and warrior-face override; the smiles and
custom faces pictured here document the earlier appearance milestone.

The thirteen linked captures show the ranged troop on the left, melee troop in
the middle and an R15 player on the right, at weapon/armor level 1. These are
real Studio renders of the exported assets. The five supplied melee skins retain
their clothing and headwear; their player/ranged counterparts use derived outfits. The final
Persian, Mauryan and Ottoman views include the corrected imported headwear.
