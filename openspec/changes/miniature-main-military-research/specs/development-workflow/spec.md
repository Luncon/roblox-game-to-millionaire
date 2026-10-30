## MODIFIED Requirements

### Requirement: Explicit script mapping

The repository SHALL provide a default Rojo mapping for the miniature game and an explicit legacy full-size mapping, without managing unrelated Studio Workspace geometry.

#### Scenario: Build the mapped scripts

- **WHEN** Rojo builds `default.project.json`
- **THEN** miniature server code is mapped beneath `ServerScriptService/Sandbox`
- **AND** miniature client code is mapped beneath `StarterPlayer/StarterPlayerScripts/MiniatureGame`
- **AND** miniature shared code is mapped beneath `ReplicatedStorage/MiniatureGame`
- **AND** the default bootstrap uses the ordinary Studio development seed rather than funded review or automated fixtures

#### Scenario: Build the preserved game

- **WHEN** Rojo builds `legacy-fullscale.project.json`
- **THEN** the previous server, client, shared and asset mappings remain available
- **AND** full-size test generators use that legacy project
