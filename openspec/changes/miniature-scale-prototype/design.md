# Design

## Context

See proposal.md. Existing production uses large fixed settlements and player combat. The user supersedes that direction with an unarmed normal-sized commander and miniature troops. The pre-redesign Git tag and full Studio backup remain immutable.

## Goals / Non-Goals

Establish a walkable scale test with recognizable existing Spartan equipment and visible unit activity. This scene is a visual/movement prototype; patrols do not establish scaled combat correctness or the final economy architecture.

## Decisions

- Use `miniature.project.json` with new scripts under `prototypes/miniature`. Explicitly map only the existing appearance libraries needed to create sanitized troops; omit production Bootstrap, profile, economy and combat services and all ordinary client combat scripts. This avoids a mode flag accidentally reaching real player storage.
- Build the scene on a compact flat plot with a full-size spawn and continuous surrounding walk space. Create simple Spartan buildings at full reference dimensions and scale models to .25. Keep player movement and selectable interaction distances at commander scale.
- Reuse WarriorRig/Equipment/NPC sanitation for three spear troops and one archer. Scale equipped clones once; capture scaled joint bases for a simple patrol gait. Use server-controlled bounded routes with noncolliding actors. Scale a cloned farmer before preparation so cached posing links use miniature offsets. Source assets are never scaled or edited.
- Use local building inspection from replicated building metadata and native ClickDetector/prompt events. UI has no purchase or combat remotes. Walk uses the ordinary character camera; Overview frames the settlement, and CharacterAdded restores Walk after respawn.
- Prototype configuration owns scale, routes and preview descriptions. No player or profile fields change. Scene motion is presentation, not authoritative damage or production simulation.

## Risks / Trade-offs

- Scaled joints/equipment could separate: scale equipped clones before capturing resting joints and verify real native positions over a route cycle.
- Small targets can be difficult to select: dedicated invisible query targets cover each building footprint and nearby prompts provide an alternative. Verify native world clicks and E input.
- Small-screen UI or overview framing could clip: bounded portrait/landscape tests plus native screenshots. Physical hardware remains separate verification.
- A new place could load production storage: explicit allowlist mapping and native absence checks for production services/remotes before Play.

## Migration Plan

Build and verify in one separate Studio place, leaving main Studio and the archived build available. Commit/push the prototype and instructions, and leave a clean prototype Edit window ready for user testing after owned verification ends. No publication or data migration.

API references: [Model scaling](https://create.roblox.com/docs/reference/engine/classes/Model) and [camera controls](https://create.roblox.com/docs/workspace/camera).
