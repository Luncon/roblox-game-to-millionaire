# Design

## Context

See proposal.md. Development owns canonical offers/fields; Economy/Profiles preserve scalar state under version-one keys. WarriorService owns independent slots and orders, encounters own validated contacts, and all navigators share soft crowd avoidance. TrainingCamp is outside the plot's left wall; terrain reservations must protect new council access. Existing themed house meshes are solid, so a usable room needs an open interior rather than placing a table inside one.

## Goals / Non-Goals

**Goals:** Compose a first formation with existing combat, medicine, paths, paid pads and isolated saves; make transitions and missing requirements visible.
**Non-Goals:** General formation editors, new damage multipliers, per-frame pathfinding, player-root constraints, new storage versions or real-player fixture data.

## Decisions

- Extend Army Camp to tier II using its existing saved level; keep the selectable camp slot and add a permanent `reinforcement` melee slot with independent lifetime/deadline and an unused camp ring point. Add missing-default `shieldLevel`, `warCouncilLevel`, `formationLevel` and `selectedFormation` scalar fields. Validate cross-field and known-civilization restrictions; preserve legacy progress and all previous scalar fields. No retroactive settlement checkpoint. Economy receives server claim civilization for faction-gated purchases rather than trusting client fields.
- Central shared formation tuning supplies one stable identifier, prices, requirements, role offsets, pace and labels. Existing physical pads buy unlocks. A council-specific service validates map-table proximity/ownership and handles selection with the army request boundary; the client only submits a known formation identifier. Room UI follows existing dark/gold panels, closes when away or switching, and shows locked/selected states. HUD adds one March Formation button with server readiness text.
- Build the council as an accessible open-front room at a reserved exterior site beside the training camp, with themed materials/banner, flat floor, map table and miniature formation markers. Reserve room, controls and access in Topography; keep the generated landscape under 2,000 static BaseParts and do not block camp entries, roads, plots or developer geometry.
- Share shield lifecycle/eligibility between equipment and accepted damage. Per-rig state initializes once when training first becomes eligible for that life; rebuilds retain charges. The second accepted frontal block removes the tagged shield clone. Damage consumes ordinary/skill cadence normally, but blocked hits cause no damage, kill rewards or accepted-damage reactions. Frontal source direction uses server contact/projectile information; no physical collision or client shield authority. Source visuals/rigs remain immutable.
- A separate formation coordinator receives current server actor snapshots and holds member rig identities. March requires actual camp containment and height, correct roles, selection/unlocks and authority. It chooses a muster anchor centered beyond the current plot's front gate, with a fixed heading toward the battlefield. Slots use lateral offsets for outer shieldmen, middle leading by a small amount, supports behind and apart. Individual existing paths assemble the group; only all-arrived permits anchor movement. One shared anchor advances at bounded pace while waiting for lagging members, supported dry local goals and crowd checks. No root teleporting or per-think full route rebuild.
- Formed fighters use encounter Hold for stationary attacks, with formation movement only when phases permit; suppress optional movement/dashes without altering contact clocks. The medic uses formation following except real enemy avoidance, continuing independent bandage casts. Shared crowd detours cannot bypass formation/medical movement restrictions. Hold preserves the group state but freezes anchor; Advance/Regroup clear all formation movement, pending locks and reservations immediately. Formation casualties enter Hold and clear the group; replacements never silently join.

## Risks / Trade-offs

- Paths, local spacing and cohesion can fight each other -> retain goals/heading, bounded tolerances and a pace gate, test actual five-body travel/bridge behavior and avoid strict every-frame slot equality.
- Permanent shield depletion can make later formations less protected -> keep the shape usable after shield breakage; no new recharge exploit or implicit healing.
- The medic may leave its rear slot under pressure -> preserve enemy avoidance and pause the group if coherence is lost rather than forcing unsafe positioning.
- Exterior additions can create navmesh holes or scenery collisions -> reserve all footprints/access before generating landscape and test all rotated plots with existing geometry fixtures.
- New slots/pads alter fixed-count fixtures -> update obsolete expectations while retaining all earlier compatibility and lifecycle assertions.

## Migration Plan

Missing-only defaults preserve existing version-one profiles; progression/selection saves per civilization, combat/march state is rebuilt each session. Implement and verify progression/slots, shields, room/selection, then marching in separate slices. Use standalone logic and fake-store Studio tests, native UI input, actual road assembly/march/cancellation and combat/healing. Review, refresh production/manual builds, clean owned windows and integrate main. Published-client and real-store restoration remain separate acceptance boundaries. Rollback removes the new gameplay while retaining old progress fields and keys; never overwrite failed loads.
