# Design

## Context

Equipment currently constructs procedural armor/headwear and an authoritative
Tool. Five melee NPC templates preserve their own skins. Ranged rigs are generated.
The new Workspace models contain mixed hats, unions, meshes, scripts and joints.
See proposal.md for the requested visual outcome and confirmed assignments.

## Goals / Non-Goals

**Goals:** Store reviewable visual assets in the repository, share safe rendering
between player and troop equipment, preserve current gear lifecycle and stats.

**Non-Goals:** Imported weapon scripts, extra attacks, avatar wardrobe management,
new damage rules or saved cosmetic selection.

## Decisions

- Export eleven normalized visual Models into assets/equipment-templates and map
  them to ServerStorage.EquipmentTemplates. Keep original Workspace imports intact.
  Stored copies exclude scripts, forces, old joints and giver objects. A virtual
  Handle anchors visual parts; hats store HeadOffset, bows preserve Tool grip,
  and the katana stores a calibrated hilt grip from actual avatar inspection.
  Keeping binary Roblox geometry preserves unions and mesh references that a
  hand-recreated procedural asset would lose.
- EquipmentVisuals reconstructs allowlisted cosmetic clones and welds them to
  the normalized Handle. Import metadata never supplies authoritative gear stats.
  Equipment owns generated Tool and armor lifecycles; each NPC retains exactly
  one explicit WarriorGrip. All nested geometry moves together.
  Live NPC gear rebuilding reasserts explicit server ownership after the new
  assembly is attached. An ordinary server-Script regression reproduced the
  engine resetting ownership to automatic mode during a rebuild near a player.
- Map hats to Sparta, Britain, Seneca and Egypt. Skip imported headwear for
  CustomMeleeModel rigs. Egyptian players use Pharaoh and generated troops Anubis.
- Map Spartan spear to players and both troop roles; Spartan shield is cosmetic
  for players/melee. Britain player/melee use the officer sword; its ranged role
  retains the musket. Japan player/melee use katana. Maurya/Persia player/melee
  use the long spear. Seneca player and existing bow ranged roles share the bow.
  Other visuals retain their existing procedural style.
- Missing/invalid assets fall back to generated visuals so a synchronization
  problem does not prevent equipping or alter combat. Saves and schema do not
  change; server currency, ownership, damage, cooldown and reward rules remain.

## Risks / Trade-offs

- Mixed source orientations/sizes → inspect head, hand and shield placement on
  actual player and moving troop rigs, including R15/native equip and R6 NPCs.
- Mesh permissions/loading → inspect rendered Studio images; published-client
  asset availability remains a separate check if it cannot be run here.
- Unsafe source descendants → sanitize saved copies and rebuild runtime clones
  from a visual allowlist; assert originals remain unchanged.
- Grip duplication or stale cosmetics → focused regression tests plus one solo
  Play check with fake storage; no extra Studio clients.

## Migration Plan

Sync repository models and scripts with Rojo, restart Play, and verify native
equipment. Revert the visual mapping or remove a template to restore procedural
fallback. Existing profiles require no migration.
