# Design

## Context

See proposal.md. Existing slot IDs are used by formations and rest positions. Purchased armyCampLevel and extraTroopClass are version-one profile fields. The troop service captures a slot's class at spawn. The current recruitment choice affects only the camp slot; removing slot definitions currently destroys living troops.

## Goals / Non-Goals

Preserve progression and lifecycle authority while making recruitment configurable. Do not renumber existing slot identities or rewrite unrelated combat planning.

## Decisions

- Retain armyCampLevel internally as a compatibility field, relabel its two purchases as Barracks Capacity I/II and move the pad beside the Barracks. This avoids destructive profile rewrites and preserves formation prerequisites. Do not present Army Camp as an independent upgrade.
- Add optional recruitMelee/recruitRanged/recruitMedic scalar fields, all missing for legacy automatic composition or all present and validated. Missing defaults derive the old lineup, so new capacity purchases retain existing automatic behavior until the owner selects a custom composition.
- Use stable combat slots warrior/ranged/camp/reinforcement. Assign selected melee preferentially to warrior/camp/reinforcement and ranged to remaining slots; the canonical 3/1 lineup preserves formation roles. Keep disabled descriptors with kind none, retaining living units and pending timers. Spawn only enabled definitions. Hospital medic remains independently bounded.
- Server validates current owner, alive character, writable profile, nearby board, whole counts, unlocked types, totals and request cadence. A physical board opens a responsive modal through the existing army remote. Client drafts are never authoritative.
- Place the Barracks at local (-148,0,-62), facing the camp, above the reserved exterior surface. Preserve the shield rack between Barracks and yard. Move spawn points and both Barracks upgrade controls there; reserve exterior geometry and keep paths clear.
- Only WarriorService's fresh eligible melee spawns defer shields; other callers and player equipment retain their existing initialization. A transient flag authorizes initial pickup under Advance or Regroup; Hold pauses. Existing Regroup collection retains its guards and same-life semantics. Add a pickup for the fourth possible melee slot.
- Apply the Persian-only spear correction to cloned visual placement, retaining common grips and source models. The Persian screen stops at 30 studs, latches a half-speed final approach after a validated clear bow opportunity within 45 studs, and uses that same pace for both anchor and member movement.

## Risks / Trade-offs

- Requested counts can differ from living counts until troops die → clearly explain future-spawn behavior and show both selected and living composition.
- Formation roles depend on class-specific stable slots → prioritize the canonical IDs and verify muster after replacements.
- Exterior relocation can expose navigation/collision issues → test all plots and civilization geometry, actual walking to supplies/camp and board interaction in native Studio.
- Optional fields permit rollback to legacy code but old code would discard custom composition on a save → keep capacity fields backward compatible; avoid claiming custom selection is rollback-persistent.

## Migration Plan

Keep profile schema/store keys and all existing progression values. Decode missing composition as legacy automatic; reject partially present or invalid custom selections without overwriting data. Validate fake-store save/reload and civilization isolation. Native Studio uses only injected FakeProfileStore; real-storage and published multi-owner client verification remain separate evidence.
