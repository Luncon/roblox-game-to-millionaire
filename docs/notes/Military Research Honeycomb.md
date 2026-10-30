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
Publication evidence will be recorded after deployment. Physical phone input and
the previously pending published-client save/rejoin check remain unverified.

The user's existing reference-note edits are preserved separately. See the
[implementation change](../../openspec/changes/military-honeycomb-layout/proposal.md)
and [military rules](Military%20Research%20Rules.md).
