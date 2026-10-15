# Design

## Context

Equipment already supports eleven inert hat/weapon templates, preserves five
custom melee skins and retains explicit NPC server ownership after rebuilds.
Players and generated troops still use generic torso armor, and seven weapon
styles need complete imported coverage. See proposal.md for the requested scope.

## Goals / Non-Goals

**Goals:** Complete thirteen civilization wardrobes and both troop weapon roles;
preserve custom art, avatar restoration and the current game authority boundaries.

**Non-Goals:** Paid asset purchases, imported AI/attack scripts, replacement body
rigs, wardrobe UI, saved cosmetic choices or balance changes.

## Decisions

- Use Studio Creator Store searches with priceFilter=free and inspect inserted
  sources in ServerStorage staging. Extract inert visual components rather than
  using marketplace controllers, Humanoids or full static rigs. Record provenance
  and discard unused source packages before Play.
- Normalize thirteen outfit assets: the five supplied skins provide their
  existing visual identity; free marketplace sources supply the other eight.
  A wardrobe contains safe classic clothing/palette plus body-anchored cosmetic
  Models with Handle, BodyPart, BodyOffset and ReferenceSize metadata. This avoids
  runtime assumptions about arbitrary nested source model names and body rigs.
- Add a small outfit adapter beside EquipmentVisuals. Map source body anchors to
  R6/R15 counterparts with bounded scale. Skip outfit replacement on custom melee
  rigs; mapped hats take precedence over outfit headwear. When an outfit is
  available, keep starter chest blocks from hiding it and retain tier insignia.
- Snapshot per-character wardrobe properties and restore only fields still owned
  by our writes. Adopt intervening external edits into the restore baseline;
  never resurrect destroyed instances. Apply safe palette colors to live body
  parts without replacing the avatar's BodyColors object.
- Reapply through the existing equipment path after CharacterAppearanceLoaded
  for genuine players. Test boundary doubles remain independent of that event.
- Map every active weapon kind to imported visuals, using existing supplied
  assets where appropriate. Stats, roles, claims, ranges, cooldowns, rewards,
  profile schema and NPC server ownership stay under existing server modules.

## Risks / Trade-offs

TroopAppearance applies a thirteen-civilization art palette and the existing
user-supplied Seneca warrior face after equipment on every NPC refresh. This
overrides outfit body colors on live troops, including custom melee clones,
while keeping source assets, head meshes, clothes and attached gear unchanged.
BodyColors and visible body parts stay consistent, and exactly one front face
is active. Player avatar appearance remains under the existing wardrobe path.
The palette is a set of fictional character art defaults, not a claim about the
skin tones of every historical member of a civilization. Opaque skin already
painted into clothing textures is retained with the original clothing artwork.

Generated R6 heads use Roblox's built-in Head SpecialMesh at classic 1.25 scale
and the configured warrior face. Keep the existing Head part dimensions and Neck
joint so headwear anchors and rig physics stay stable. Custom melee clones
retain their original head meshes while receiving the configured face and tint.

- Invalid/restricted marketplace content → verify insertion, strip unsafe content,
  choose another free asset when necessary, and keep procedural fallback.
- Static, oversized or complex source art → export only small relevant body
  cosmetics and verify native avatar/moving troop fit before acceptance.
- Late appearance or external wardrobe changes → meaningful snapshot/restore
  regressions plus an actual native player appearance/respawn check.
- R6/R15 alignment and mesh loading → inspect all civilization looks in Studio,
  with native input, NPC movement and unchanged combat regressions. Published
  asset loading and multiplayer load remain separate checks if unavailable.

## Migration Plan

Sync normalized assets/scripts with Rojo and restart Play. No profile migration
is needed. Removing a missing/invalid template retains procedural fallback;
clearing equipped outfits restores the original avatar wardrobe.
