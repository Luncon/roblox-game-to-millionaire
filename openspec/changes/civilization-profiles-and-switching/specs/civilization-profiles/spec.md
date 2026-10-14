# Civilization Profiles

## Purpose

Preserve each player's independent civilization progress across sessions while protecting stored profiles from failed loads and concurrent writers.

## ADDED Requirements

### Requirement: Independent civilization progress
Each player SHALL retain separate coins, settlement, weapon, armor and barracks levels for every civilization. Loading a selected civilization SHALL rebuild its settlement, gear, controls and troop capacity from those values. Current troop health, identities, positions and replacement deadlines SHALL not be saved.

#### Scenario: Return to an established civilization
- **WHEN** a player rejoins and selects a previously played civilization
- **THEN** its saved currency and upgrade levels return
- **AND** selecting an unstarted civilization begins at zero coins and level one without changing earlier progress

### Requirement: Safe profile loading
Only a successful read of a missing profile SHALL create defaults. Failed, malformed or unsupported profiles SHALL block selection and progression without replacing stored data. Players SHALL receive a loading/error state and a bounded retry path.

#### Scenario: Existing profile fails to load
- **WHEN** storage is unavailable or the saved record is invalid
- **THEN** no fresh economy account or civilization claim is created
- **AND** no default progress is saved over the existing record

### Requirement: Validated server state
Saved currency SHALL be a finite integer between zero and one billion. Saved levels SHALL be integers from one through four; weapon, armor and barracks levels SHALL not exceed settlement level. Clients SHALL not supply saved balances or upgrade levels.

#### Scenario: Invalid stored progression
- **WHEN** a record contains nonfinite currency or an upgrade above its settlement cap
- **THEN** loading fails safely without modifying the stored record

### Requirement: Exclusive ordered persistence
At most one session SHALL be authorized to mutate a player's loaded profile. Save and retry operations SHALL preserve per-player write order and latest in-memory changes. A lost or expired session lease SHALL stop new progression mutations, including kill rewards.

#### Scenario: A second server takes ownership
- **WHEN** an expired session is replaced and the old server attempts to save
- **THEN** the old server cannot overwrite the newer profile even if the newer session has already released its lease

### Requirement: Periodic and final saves
The server SHALL save periodically and attempt a final save on departure and shutdown. Finalization SHALL stop mutations before snapshotting and releasing ownership. A player who leaves during load SHALL not be initialized by a late result. Save failures SHALL not be reported as successful saves.

#### Scenario: Progress changes during an autosave
- **WHEN** additional coins arrive while a save is waiting on storage
- **THEN** the newer state remains pending for a later save or the final flush
- **AND** departure captures that newest state before closing the economy

### Requirement: Isolated persistence verification
Automated tests SHALL use an injected store without accessing player production data. Studio development persistence SHALL use a separate storage scope from live play. Verification records SHALL distinguish fake-store lifecycle tests from real storage restoration.

#### Scenario: Run a Studio regression
- **WHEN** an isolated test place starts a gameplay suite
- **THEN** its persistence reads and writes use the test store
- **AND** production profiles remain untouched
