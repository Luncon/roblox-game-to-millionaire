# Military Research Honeycomb

The October 30, 2026 layout revision follows the upright, touching hexagons in
[the Mini Wars research screenshot](../assets/Pasted%20image%2020261028150336.jpg)
from [the reference collection](Mini%20Wars%20References.md).

Army Training is the starting tile. Army Size I joins its upper-left edge,
Officer Training its left edge and Field Bandages its lower-left edge. All 29
military upgrades grow to the left in a connected honeycomb. Ten civilian future
tiles sit on the right, with seven reserved military tiles on the left.
Separate connector lines are removed; adjacent tiles share their hexagonal edges.

This is a presentation change. Existing research IDs, prices, timers,
requirements, effects and saved progress remain unchanged. Touching tiles can
also be neighbors without a prerequisite relationship: the selected tile's
requirements and the server's existing rules govern purchases.

The implementation uses a pure axial layout, native upright hexagon fills and
nonoverlapping selection centers. At minimum zoom the center buttons remain
45×45 pixels. Pan, zoom, selected details and panel guards remain client-session
state.

## Verification

Six automated geometry cases pass, including all 1,035 tile-pair overlap checks,
exact shared-edge vertices, three left root neighbors, connected military tiles,
unique cells and complete canvas bounds. All 249 miniature logic cases pass.
An independent review also deliberately changed the neighbor-distance rule;
the geometry test failed with `Unexpected military root neighbor`. The original
module was then restored byte for byte and formatting/lint passed.
The native Studio interaction run passed all 29 center selections and 29 corner
selections, three left-face corner selections at minimum zoom, pan and zoom,
paused/out-and-back drag suppression, higher-layer overlay suppression, disabled
ScreenGui guards and retained drafts. Both ordinary and IgnoreGuiInset rendering
were exercised. All four supported viewport sizes retained minimum selection
targets. The fixture used isolated presentation copies and recorded zero actual
gameplay requests; it did not change player progress or real storage.

That run caught and fixed a real pointer-coordinate bug: InputObject.Position
already accounts for the top-bar inset. Subtracting the inset again selected a
neighboring hexagon. Native input and GetMouseLocation readings confirmed the
correction. Earlier failed runs are not counted as passing evidence.

The full development gate passed 36 OpenSpec items, 13 Node cases, 421 Luau syntax
compilations, 244 preserved legacy logic cases and 249 miniature logic cases,
plus the existing mount asset checks. Native painted geometry passed all four
viewport sizes: 46 tiles, 99 neighboring shared borders, no connector frames and
29 nonoverlapping center targets. Roblox stores UDim offsets as integers; the
fixture checks the exact quantized offsets separately from the exact pure
geometry. Maximum native shared-vertex difference was 0.862 pixels, covered by
the two-pixel outlines. The first native geometry assertion incorrectly expected
fractional UDim offsets; that fixture was corrected without changing geometry.
Evidence is retained locally in
[honeycomb-native-verification.json](../../.cache/honeycomb-native-verification.json).
Physical phone input and
the previously pending published-client save/rejoin check remain unverified.

The user's existing reference-note edits are preserved separately. See the
[implementation change](../../openspec/changes/military-honeycomb-layout/proposal.md)
and [military rules](Military%20Research%20Rules.md).

## Release status: published version 258

The geometry and UI were committed and pushed in **10441cc** and **30622de**.
Both the default preview and clean production artifacts were rebuilt. The clean
production artifact contains **107 matching script sources**, no fake store or
verification attribute, and only Camera/Terrain in Workspace. Its SHA-256 is
`b19f2092c04f5b133cd9c7783886c625d990cbd42b20200b6af3b3b542e3e14e`.

Studio Save to Roblox As selected the existing private Clash of Civilizations
experience and its existing place, **73839918762778 / 10770758443**. Roblox
requested asset permissions. The Studio log then recorded `PublishCancelled`
during the permission stage, followed by editor shutdown; both open Studio
windows exited. The user clarified that they closed the windows because Studio
froze. Logs show an HTTP 400 from the asset-permission check and 65
`AssetTypeNotEnabled` grant failures. Those errors alone do not establish that
65 assets cannot load. Roblox has documented permission issues with external
place files in its [asset privacy announcement](https://devforum.roblox.com/t/full-release-privacy-for-newly-created-image-mesh-and-decal-assets/4620416).

A fresh read-only cloud open initially reported **draft 256**. Its research UI
and shared layout matched the new build, but it also contained FakeProfileStore
and the temporary preview Bootstrap. Both sources were backed up and verified
byte for byte against their tracked development files. Only that pristine test
module was removed and Bootstrap was replaced with the tracked production
bootstrap. No scenery, legacy folders or other objects were deleted. All **107
production sources then matched the clean artifact**, with no fake store,
missing/unexpected sources or verification attribute.

Ordinary Publish from the existing target succeeded with one responsive Studio
window. Creator Hub independently shows **version 258** with the Published
Version checkmark (October 30, 2026, 11:36 AM local). The screenshot is retained
locally as
[military-honeycomb-published-version-258.png](../../.cache/military-honeycomb-published-version-258.png).
The failed Save As path was not used for the final release. Private visibility,
place identity and existing persistence settings were not changed.
An independent Studio `EditPlaceRevision` open explicitly requested **258** and
opened **Place1 (Version 258)**. All **107 published script sources** match the
reviewed release, with no unexpected/missing scripts. Historical revision
DataModels report zero identity/version metadata, so the requested revision and
window title identify this audit; cached editor metadata is not publication proof.
See the [release record](../releases/military-honeycomb-v1.json) and local
[source audit](../../.cache/honeycomb-release-edit-audit.json).
