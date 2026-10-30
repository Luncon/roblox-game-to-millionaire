# Spec Delta

## Purpose

Preserve miniature civilization progress across server sessions while preventing concurrent writers or failed storage requests from replacing player data.

## ADDED Requirements

### Requirement: Durable independent miniature progress
The game SHALL save and restore valid miniature progress independently per player and civilization, including Coins, goods, held building plans, placed buildings, completed and partial military research, and army group presets. New civilizations SHALL receive the ordinary starting state without test funding.

#### Scenario: Leave and rejoin
- **WHEN** a player leaves after paid purchases, production and partial research and later rejoins
- **THEN** their saved miniature progression restores in their selected civilization
- **AND** active production and research do not gain offline time
- **AND** deployment targets, troop lives and outpost ownership do not restore

### Requirement: Exclusive profile authority
The game MUST use atomic session ownership to reject concurrent profile writers and stale saves. Lost or expired ownership SHALL stop progression, purchases and owned-army authority.

#### Scenario: Conflicting server
- **WHEN** another server owns an unexpired profile lease
- **THEN** a new session cannot replace its data or grant writable progress
- **AND** a stale server cannot overwrite data after ownership changes

### Requirement: Failed storage never creates replacement progress
Failed or invalid loads MUST leave stored records unchanged and gameplay unavailable. Transient failures SHALL receive bounded retries and an actionable status. Save failures MUST remain visible and SHALL NOT report successful durability or renew local authority without a confirmed save.

#### Scenario: Corrupt or unavailable profile
- **WHEN** loading throws, finds malformed saved progress or finds unsupported schema data
- **THEN** no default profile overwrites that record
- **AND** the player sees that progress is unavailable and how to retry or rejoin

### Requirement: Safe session lifecycle
Autosave, leave and server shutdown SHALL serialize profile writes and attempt bounded final saves. A returning player SHALL wait for an earlier same-server release before acquiring a fresh session. Storage callbacks SHALL not yield or commit expired ownership.

#### Scenario: Rejoin while leaving save is pending
- **WHEN** a player rejoins while the earlier Player instance is still releasing its profile
- **THEN** the new player obtains a fresh load after that release completes
- **AND** old cleanup cannot remove the new context or its saved progression

### Requirement: Isolated persistence environments
Miniature live profiles MUST use a namespace distinct from legacy full-size data and all verification data. Automated gameplay fixtures SHALL use injected fake storage. Studio SHALL not silently write the live scope.

#### Scenario: Replace the full-size game
- **WHEN** the miniature game first starts for a player with legacy progress
- **THEN** their legacy record remains unchanged
- **AND** the miniature game loads or creates only its own independent profile
