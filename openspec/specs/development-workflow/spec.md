# Development workflow

## Purpose

Provide a reproducible planning and script-sync setup for a Luau Roblox project,
with a shared Obsidian vault and repository-local OpenSpec dependency.

## Requirements

### Requirement: Pinned development tooling

The repository SHALL declare a reference Node.js version and an exact OpenSpec
development dependency, and SHALL include an npm lockfile.

#### Scenario: Install the planning tool

- **WHEN** a developer uses the declared runtime and runs `npm ci`
- **THEN** the lockfile determines the installed tool dependency versions
- **AND** `npm run openspec -- --version` reports the pinned OpenSpec version

### Requirement: Codex planning workflows

The repository SHALL include the six core OpenSpec Codex skills and a project
configuration using the `spec-driven` schema.

#### Scenario: Discover planning workflows

- **WHEN** a compatible Codex client loads this repository's skills
- **THEN** the explore, propose, apply, update, sync, and archive workflows are available

### Requirement: Shared Markdown vault

The repository SHALL be usable as an Obsidian vault whose notes and specifications
are the same files used by developers and agents.

#### Scenario: Open the vault

- **WHEN** a developer opens the repository folder as an Obsidian vault
- **THEN** `START_HERE.md` links to the game vision and setup instructions
- **AND** new notes and attachments are directed into the configured documentation folders

### Requirement: Explicit script mapping

The repository SHALL provide a Rojo mapping for server, client, and shared Luau
code without managing the Studio-built Workspace.

#### Scenario: Build the mapped scripts

- **WHEN** Rojo builds `default.project.json`
- **THEN** server code is mapped beneath `ServerScriptService/Game`
- **AND** client code is mapped beneath `StarterPlayer/StarterPlayerScripts/Game`
- **AND** shared code is mapped beneath `ReplicatedStorage/Shared`

### Requirement: Verification boundaries

Documentation SHALL distinguish specification validation and Rojo builds from
runtime gameplay verification.

#### Scenario: Validate specifications

- **WHEN** a developer runs `npm run check`
- **THEN** OpenSpec validates specifications in strict mode
- **AND** the setup guide identifies the separate Studio connection check

### Requirement: Pinned Luau development tools

The repository SHALL pin Selene, StyLua and Lune release versions and archive
SHA-256 digests, and SHALL provide an explicit local installer without enabling
npm installation scripts or changing production project mappings.

#### Scenario: Install native tools

- **WHEN** a developer runs `npm run setup:tools` on a supported platform
- **THEN** official archives are verified against committed digests before extraction
- **AND** tools are installed in ignored project-local storage
- **AND** subsequent checks do not require tool downloads

### Requirement: Automated offline development gate

The repository SHALL provide automated syntax and deterministic logic tests plus
strict changed-file lint and formatting checks, and SHALL run them with strict
OpenSpec validation on GitHub pushes and pull requests.

#### Scenario: Check a working change

- **WHEN** a developer runs `npm run check:dev`
- **THEN** changed, staged and untracked first-party Luau files are linted and format-checked
- **AND** the test command compiles all first-party Luau source and runs the standalone logic suite
- **AND** a failed selected-file check or test produces a nonzero exit status
- **AND** separate full-scan commands expose existing lint and formatting diagnostics

#### Scenario: Preserve runtime verification boundaries

- **WHEN** offline tests pass
- **THEN** fixtures use explicit engine doubles and injected fake profile storage
- **AND** documentation still requires Studio or Roblox client checks for native gameplay
