# Saved civilization progress

Each player has separate progress for all 13 civilizations. The server loads the
player's profile before allowing civilization selection, coin earning, upgrades
or kill rewards. Choosing a civilization restores its coins, settlement, weapons,
armor and barracks. A civilization you have not started begins with zero coins
and level-one upgrades, without changing your other civilizations.

Use **Change civ** in the HUD to reopen the selector. It shows your saved progress
and which civilizations are available in this server. Switching to a free
civilization keeps your plot, saves the old civilization's current progress in
memory, and rebuilds the new settlement, equipment and army. Selecting an occupied
civilization leaves your existing settlement and progress intact. You can cancel
the selector or choose your current civilization without restarting it.

On a later join, choose an available civilization to continue it. The physical
plot is assigned by that server; plot ownership is not part of your saved profile.
Cross-server civilization matchmaking remains planned.

## What is saved

The version-one profile stores these five fields for each started civilization:

| Field | Meaning | Accepted values |
| --- | --- | --- |
| `coins` | Civilization currency | Integer from 0 through 1,000,000,000 |
| `level` | Settlement stage | Integer from 1 through 4 |
| `weaponLevel` | Player and troop weapon tier | Integer from 1 through settlement level |
| `armorLevel` | Player and troop armor tier | Integer from 1 through settlement level |
| `barracksLevel` | Barracks upgrade tier | Integer from 1 through settlement level |

Level-one barracks state is stored even before the building unlocks at settlement
stage 2. Restoring that stage deploys its automatic melee troop; barracks IV also
deploys the ranged troop. Current NPC models, health, positions, corpses,
projectiles and replacement countdowns are temporary. Switching civilization or
rejoining creates the appropriate army again, rather than restoring a battle in
progress. Character resets within the same civilization still preserve the
current army and its timers.

The envelope is `{schemaVersion = 1, civilizations = {...}, session = {...}?,
savedAt = ...?}`. Civilization dictionary keys use the IDs in
[Civilizations](../src/shared/Civilizations.luau). `session` contains a unique token
and an expiry timestamp; it is removed after an acknowledged final release.
Account revisions, click tokens, purchase cooldowns, avatar health and plot IDs
are excluded. [ProfileData](../src/server/ProfileData.luau) validates and copies
the values; it rejects malformed and unsupported profiles instead of repairing
them into defaults.

## Saving and session ownership

One player key, `User_<userId>`, holds every civilization in the
`CivilizationProfilesV1` DataStore. Saving them together prevents separate writes
from losing another civilization's progress. Normal clicks and combat update
server memory; they do not make a storage request for every coin.

[ProfileService](../src/server/ProfileService.luau) attempts an autosave every
30 seconds and a final save on departure and server shutdown. It uses a
120-second session lease, renewed by saves, to keep two servers from writing the
same player at once. Storage operations have up to three attempts, with one- and
two-second waits between failed attempts. Writes and retries are serialized for
each player. New progress arriving during a save remains pending for the next
save; finalization freezes mutations before capturing the latest state.

Every write after acquisition requires the original stored token and a valid
lease. A missing token does not authorize an old server to resume writing. A
player who leaves during loading cannot be initialized by a late response; any
lease acquired for that departed session is finalized safely. These checks use
Roblox's atomic [UpdateAsync](https://create.roblox.com/docs/reference/engine/classes/GlobalDataStore#UpdateAsync)
storage boundary.

Autosaves and final retries reduce lost progress but cannot guarantee that a
crash or interrupted shutdown saves the latest action. A failed request can also
have committed without returning an acknowledgment. Retries use absolute
snapshots, avoiding duplicate currency. If a final release commits but its
response is lost, the service can conservatively report failure even though
the progress was stored and the lease removed. It will not reacquire ownership
to overwrite that uncertain result.

## Loading and failure feedback

Only a successful storage operation that finds no profile creates a new profile.
An API error, malformed data or a future schema version blocks selection and
progression; it never resets saved progress. The selector offers **Retry** while
you have no civilization claim. Load attempts are limited to one start every
10 seconds, and a live session in another server remains locked until it releases
or expires.

The HUD reports loading, saving and delayed saves. A temporary save failure can
allow play while the previously confirmed lease remains valid; autosaving retries
later. A lost or expired lease freezes coin earning, purchases and kill rewards.
The HUD asks you to rejoin to reload safely. The old session does not automatically
take ownership again from stale memory.

## Studio and test isolation

Production startup selects the scope from the execution environment:

| Environment | DataStore | Scope |
| --- | --- | --- |
| Roblox game servers | `CivilizationProfilesV1` | `Live` |
| Studio using the normal bootstrap | `CivilizationProfilesV1` | `StudioDevelopment` |
| Generated automated test place | Injected in-memory fake store | No real DataStore calls |

Studio development progress and live-player progress are separate. The isolated
test bootstrap shares its fake backend only within a Play run; starting a new
run starts a new test backend. See [setup](SETUP.md) for Studio API access and
[playtest records](PLAYTEST.md) for executed checks. Roblox documents Studio's
ability to access an experience's stored data in its
[DataStore guide](https://create.roblox.com/docs/cloud-services/data-stores).

Fake-store Studio specs cover validation, restoration, concurrent saves, lease
fencing, callback replay, uncertain outcomes and leaving during load. These tests
do not establish real DataStore access or real-storage leave/rejoin restoration.

Real storage restoration was also observed using the normal bootstrap with
`CivilizationProfilesV1` in `StudioDevelopment`. Native floor interactions earned
37 coins and purchased settlement II for 25 coins. After stopping Play for the
final save and starting a fresh Play session, a real DataStore read and native
GUI selection restored Sparta with 12 coins, settlement II, weapon I, armor I
and barracks I, including its tier-one equipment and one melee troop. The longer
55-click helper stopped at its 38th click after an activation timeout; this is
partial interaction coverage, not a completed 55-click run. See
[playtest records](PLAYTEST.md) for the detailed evidence. This verifies Studio
development storage, not live-scope or published Roblox-client restoration.
