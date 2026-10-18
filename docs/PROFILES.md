# Saved civilization progress

Each player has separate progress for all 13 civilizations. The server loads the
player's profile before allowing civilization selection or economy mutations.
Choosing a civilization restores its coins, upgrade/building levels, farm reserve
and extra troop choice. A civilization you have not started begins with zero coins,
level-one original tracks, unowned new buildings and an empty farm reserve,
without changing your other civilizations.

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

The version-one profile stores these twenty required scalar fields and three optional recruitment counts per civilization:

| Field | Meaning | Accepted values |
| --- | --- | --- |
| `coins` | Civilization currency | Integer from 0 through 1,000,000,000 |
| `level` | Settlement stage | Integer from 1 through 50 |
| `weaponLevel` | Player and troop weapon tier | Integer from 1 through settlement level, maximum 50 |
| `armorLevel` | Player and troop armor tier | Integer from 1 through settlement level, maximum 50 |
| `barracksLevel` | Barracks upgrade tier | Integer 1–6, no higher than settlement; V requires 8, VI requires 14 |
| `trainingLevel` | Training Yard purchase | 0 or 1; owning it requires settlement 5 |
| `farmLevel` | Farm tier | 0–2; I requires settlement 7, II requires 12 |
| `workersLevel` | Worker Camp tier | 0–2; I requires settlement 7, II requires 12; no higher than farm tier |
| `armyCampLevel` | Barracks capacity purchase tier (legacy storage key) | 0–2; I requires settlement 10/Barracks IV; II requires settlement 18/Barracks VI |
| `farmCoins` | Uncollected farm reserve | Integer 0–60, or 0–180 with Storehouse I; must be 0 without a farm |
| `extraTroopClass` | Legacy automatic reinforcement class | `warrior` or `ranged`; default `warrior` |
| `blacksmithLevel` | Weapon-price workshop | 0 or 1; owning it requires settlement 13 |
| `armorerLevel` | Armor-price workshop | 0 or 1; owning it requires settlement 13 |
| `storehouseLevel` | Reserve-capacity building | 0 or 1; owning it requires settlement 16 and Farm I |
| `skillLevel` | Purchased weapon-family skill tier | Integer 0–5; positive tiers require Training Yard I and weapon level at least tier × 10 |
| `hospitalLevel` | Hospital purchase | 0 or 1; requires settlement 10 and Training Yard I |
| `shieldLevel` | Shield Training | 0 or 1; requires Sparta, Rome or Persia, settlement/armor 15 and Armorer I |
| `warCouncilLevel` | War Council purchase | 0 or 1; requires settlement 19 and Training Yard I |
| `formationLevel` | Civilization formation training | 0 or 1; requires Sparta, Rome or Persia, settlement 20, shields, council, Army Camp II and hospital |
| `selectedFormation` | Council selection | `none`, purchased `spartan-shieldwall` for Sparta, purchased `roman-shield-guard` for Rome, or purchased `persian-archer-screen` for Persia; missing defaults to `none` |

| `recruitMelee` | Selected future melee count | Optional integer 0–4; selected fighter sum must fit Barracks capacity |
| `recruitRanged` | Selected future ranged count | Optional integer 0–4; positive counts require Barracks IV |
| `recruitMedic` | Selected future medic count | Optional integer 0–1; positive count requires Hospital I |

All three recruitment fields must be absent together (legacy automatic lineup)
or present together (custom lineup). Missing counts do not become zero: old
purchases and `extraTroopClass` still determine the automatic composition.
Explicit choices save per civilization. `armyCampLevel` remains the compatibility
key for the two Barracks Capacity purchases; no owner repurchases those slots.
Composition changes preserve current troop lives and pending replacement timers.

Both building milestones retain `schemaVersion = 1` and the existing store/key.
Only missing new fields receive defaults: building levels and reserve become
zero, and troop choice becomes `warrior`. Explicitly malformed supplied values
fail validation. Old coins and levels are not reset. Saved settlements already
at 10–50 do not retroactively require the new settlement-10 checkpoint; buying
the transition from 9 to 10 does require its buildings.

The economy expansion adds only `blacksmithLevel`, `armorerLevel` and
`storehouseLevel` to the eleven-field state. Older records receive zero for
these missing fields while retaining their existing purchases, reserve, class
and balances. Farm II with Worker Camp I is valid; Worker Camp II with Farm I
is rejected. Premature Barracks V/VI and reserves above the owned storage
capacity are rejected without resetting the profile.

The fifty-level update preserves existing coins, numeric levels, schema version
and DataStore keys. Existing level four stays four and receives the new gradual
visuals and combat curve; it is not remapped to 50. Each field has its own maximum,
so a high settlement cannot accidentally admit unsupported barracks levels.
An older four-level build cannot safely load newly saved high levels. Any rollback
must retain compatible validation rather than clamp or reset stored progress.
A pre-building or eleven-field writer could silently omit newer fields on its
next save; rollback must retain all twenty fields, expanded tier validation
and capacity rules.

Level-one barracks state is stored even before the building unlocks at settlement
stage 2. Restoring that stage deploys its automatic melee troop; barracks IV also
deploys the ranged troop. Army Camp I adds a third slot whose saved class is
used at its next spawn. Current NPC models, health, positions, corpses,
projectiles and replacement countdowns are temporary. Switching civilization or
rejoining creates the appropriate army again, rather than restoring a battle in
progress. Character resets within the same civilization still preserve the
current army and its timers.

Farm reserve and storage ownership are saved; the farm clock is not. Switching/rejoining preserves earned
reserve but discards unfinished intervals and creates no offline income. Farm
worker poses, crop animation and transient advance/hold/regroup orders are not
saved. A selected civilization starts with the advance order.

The envelope is `{schemaVersion = 1, civilizations = {...}, session = {...}?,
savedAt = ...?}`. Civilization dictionary keys use the IDs in
[Civilizations](../src/shared/Civilizations.luau). `session` contains a unique token
and an expiry timestamp; it is removed after an acknowledged final release.
Account revisions, click tokens, purchase cooldowns, farm clocks, avatar health and plot IDs
are excluded. [ProfileData](../src/server/ProfileData.luau) validates and copies
the values; it rejects malformed and unsupported profiles instead of repairing
them into defaults.

## Weapon skill extension

Weapon skills add one scalar, `skillLevel`, to the existing fourteen fields.
Only a missing value defaults to zero; supplied malformed values, unsupported
levels, missing training or insufficient weapon levels fail validation. All
copies, economy snapshots and saves preserve twenty fields under the existing
version-one keys and scopes. Skills save separately for each civilization.
Purchases preserve troop health and pending replacement deadlines. Player and
owner/slot/family cooldowns are transient but survive resets/replacements and
civilization switches within the same server; they are not restored across servers.

Rollback must retain twenty-field readers and writers, even when skills are
disabled. A fourteen-field writer would silently discard purchased skills.
Automated save/reload checks use the injected FakeProfileStore; this does not
establish real Roblox storage restoration for the new field. See
[weapon skill behavior](WEAPON_SKILLS.md) and [runtime evidence](PLAYTEST.md).

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
later. A lost or expired lease freezes coin earning, purchases, farm production/
collection, troop-choice changes and kill rewards.
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

Hospital ownership adds the sixteenth scalar, `hospitalLevel` (0 or 1). Only a
missing value defaults to zero; supplied malformed values or Hospital I without
settlement 10 and Training Yard I reject the record. The existing version-one
keys, store names and scopes remain unchanged. All original fifteen fields are
preserved. Bandage flights, recovery clocks, cooldowns and troop health are never
saved. A rollback must retain a hospital-field-aware profile writer even when
medical deployment is disabled; an older writer would discard the purchase.

Shield/council/formation fields use missing-only defaults under unchanged
version-one keys. Malformed values and cross-field/faction inconsistencies fail
loading rather than resetting progress. Shield charges and march state are
transient and never saved. Switching a player character away from Sparta and
back during the same life preserves its spent shield charges.

Persian deployment phases, local guard bounds, shield rack trips and replenished
charges are transient. All twenty saved scalars and version-one keys stay
unchanged; a recalled rack pickup restores only the current NPC life's charges.
