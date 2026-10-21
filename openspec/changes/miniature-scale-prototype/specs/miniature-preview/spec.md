# Spec Delta

## Purpose

Let players assess miniature civilization scenery and troops beside a normal-sized commander before committing to the redesigned economy.

## ADDED Requirements

### Requirement: Isolated scale preview
The prototype SHALL launch separately from production, show a Spartan house, farm and barracks at quarter scale, and retain the player's normal avatar size. It SHALL NOT load or save player profiles, grant player weapons or activate player combat.

#### Scenario: Enter the preview
- **WHEN** a player starts the prototype
- **THEN** the player can walk beside the three miniature buildings with an unarmed normal-sized avatar
- **AND** production progression and saved profiles remain untouched

### Requirement: Living miniature scene
The preview SHALL show four equipped miniature soldiers on bounded patrol routes and two miniature workers tending the farm. Movement and equipment SHALL fit the quarter-scale scene. Buildings and actors SHALL NOT obstruct the commander. Source templates SHALL remain unchanged.

#### Scenario: Watch the settlement
- **WHEN** the player watches the scene for a complete route cycle
- **THEN** soldiers patrol and workers visibly move or tend the field without escaping their routes or losing equipment
- **AND** the player can walk through the scene without pushing actors or becoming blocked

### Requirement: Building inspection and camera
Each preview building SHALL be selectable with native pointer/touch input or a nearby interaction prompt and show its name and purpose. The interface SHALL offer Walk and Overview camera controls, remain reachable in narrow and landscape layouts, and recover walking camera control on respawn.

#### Scenario: Inspect and return to walking
- **WHEN** the player selects each building and switches between Overview and Walk
- **THEN** the matching information appears and the camera changes without granting rewards or changing scene state

#### Scenario: Respawn in overview
- **WHEN** the player respawns while using Overview
- **THEN** normal camera control follows the new character and the miniature scene remains available
