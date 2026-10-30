# Miniature Live Release

Current presentation update: the touching research honeycomb was published as
**version 258** on October 30, 2026. See [Military Research Honeycomb](Military%20Research%20Honeycomb.md)
for its source audit and native UI evidence. The version 250 evidence below
records the initial persistent miniature release.

Initial release: **PUBLISHED — version 250** (current update: **258**, linked above). The existing Clash of Civilizations place has
been replaced with the miniature game. The real Roblox client starts successfully;
published-client save/rejoin still needs a physical-input check. The approved
implementation is tracked in
[miniature-live-release](../../openspec/changes/miniature-live-release/proposal.md).

The authorized target is place **73839918762778**, universe **10770758443**,
owned by **SmithLucas5652**, UserId **68716649**. These identifiers were checked
read-only against the connected Studio server. Its Studio `PlaceVersion` value
was zero; that does not identify the current cloud version. Existing audience
and access settings are retained.

## Storage contract

The reviewed server adapter uses **MiniatureCivilizationProfilesV1**, scope
**Live**, with canonical positive `player:<UserId>` keys. This miniature record
is separate from **CivilizationProfilesV1**; legacy full-size records are neither
translated nor overwritten. New miniature civilizations start with the ordinary
**200 Coins**, council, house and farm, without test grants or completed research.

Sessions validates records before gameplay and owns atomic acquisition, lease
renewal and serialized saves through `UpdateAsync`. Its store interface accepts
only the explicitly injected fake adapter or reviewed persistent adapter. A
failed/corrupt load does not become a replacement default. Confirmed saves carry
`lastSavedAt`; storage errors and expired/lost ownership remain visible and do
not grant writable progress. The server retains action, currency and combat
authority. Coins, goods, held plans, placements, military research and army
presets save per player and civilization. Deployment targets, current troop
lives, outpost ownership and offline production/research time do not restore.

Ordinary `default.project.json` and automated gameplay tests continue to use
temporary injected storage. The clean scale preview has no profile or economy
bootstrap. Fake profile keys retain
`miniature-development:<UserId>`. The live bootstrap is separate. Studio real
storage requires an explicit unique **Verification_…** scope; it cannot silently
open Live. Regression tests never use real player storage. Roblox documents
that data stores are shared across places in an experience and that Studio
storage access needs particular care; see the
[official data-store guide](https://create.roblox.com/docs/cloud-services/data-stores).

The HUD shows persistent loading/retry/failure/read-only guidance. Temporary
Studio progress is labeled temporary. A live profile is called saved only after
the server reports a confirmed save timestamp. This display sends no gameplay or
storage request. A missing startup service produces a rejoin message instead of
an empty interface.

## Release artifact and rollback

Run `npm run build:miniature-release` to generate the ignored
`.cache/miniature-release.project.json`, then build it with Rojo. It is named
`ClashOfCivilizationsRelease`, uses port **34878**, and records the authorized
place/universe plus a matching serve-place allowlist. It explicitly maps one live
Bootstrap, the shared actual gameplay modules and one Main client. It excludes
FakeProfileStore, funded bootstraps, test bots and diagnostic autorunners. The
generator cannot override the target or enable verification from CLI flags.
The bootstrap also validates actual runtime place, universe and creator identity.
Generating or building this mapping does not publish it.

The fresh pre-release target backup is preserved at
[pre-miniature-live-release-2026-10-30.rbxl](../../assets/place-backups/pre-miniature-live-release-2026-10-30.rbxl).
It is **553,516 bytes**, SHA-256
`46173413da0c0b9fcb8638348322861d155967278089df6bae500b60bad03c9a`.
Native Studio Download a Copy produced it before replacement. A separate Lune
deserialization check confirmed intact legacy `Game.Bootstrap` and no miniature
`Sandbox`. This is a backup of the actual editor copy, not an inferred cloud version.

The older historical full-size place is also preserved at
[pre-miniature-redesign-2026-10-20.rbxl](../../assets/place-backups/pre-miniature-redesign-2026-10-20.rbxl),
with its managed mapping at
[legacy-fullscale.project.json](../../legacy-fullscale.project.json). A confirmed
published cloud version remains pending.

Rollback means opening the preserved pre-release place and publishing that
reviewed version back to the same authorized target, then verifying fresh server
startup. It does not delete either profile store. Preserve the miniature source
and release evidence while restoring the previous place.

Use authenticated Studio publishing for the final reviewed Edit artifact. The
mapped original equipment bank includes UnionOperations, and Roblox's
[place-publishing API guide](https://create.roblox.com/docs/cloud/guides/usage-place-publishing)
directs creators to Studio for modified PartOperation and certain other asset
types. Publishing a generated runtime Play world would include transient state;
the source release build is the publication artifact.

## Verification evidence

On October 29, 2026 the orchestrator verified the actual Roblox backend in the
unique **Verification_release_1793329791014** scope using the real adapter and
Sessions. The deliberately synthetic test record used `player:68716649` and all
thirteen civilizations. It restored Sparta with **321 Coins**, one held training
plan, seven goods, twelve farm output and **17 seconds** of partial Army Training;
Egypt restored **654 Coins**, while Rome retained **200 Coins**. A rival session
was refused, and two final-release/fresh-session reloads succeeded. The manual
helper is [MiniaturePersistence.luau](../../tests/manual/MiniaturePersistence.luau);
the local evidence is
[miniature-real-storage-verification.json](../../.cache/miniature-real-storage-verification.json).
Temporary verification modules were removed. This was native Studio API access
to a separate real backend scope, **not** published-server or human-client rejoin
verification, and none of these synthetic values were written to Live or legacy
storage.

The visible three-client fixture separately demonstrated paid construction and
three neutral outpost captures. Its later Roman takeover assertion timed out at
**313.27 seconds**. That partial result is recorded in
[Three Player Conquest Playtest](Three%20Player%20Conquest%20Playtest.md); it is
not evidence of a successful enemy takeover or durable storage.

The final `npm run check:dev` gate passed **35 OpenSpec items, 13 Node cases,
419 first-party syntax compilations, 244 legacy logic cases and 243 miniature
logic cases**, plus the unchanged mount asset checks. Changed-file Selene and
StyLua passed with no diagnostics. The 18 new logic cases include four storage
adapter cases and fourteen session durability cases. The release closure check
verifies mapped dependencies, one live Bootstrap/Main, retained assets and no
fake/test startup.

Native Studio also passed **nine Runtime lifecycle cases**, using actual Runtime
and Sessions with fake storage, virtual clocks, native Bindables/Models and
explicit service doubles. These cover retries, corruption refusal, lease renewal
before civilization selection, blocked loads, rapid rejoin, stale Player rejection,
autosave failures, terminal authority loss, paused research and bounded parallel
shutdown. They are lifecycle fixtures rather than real multiplayer players.
The actual HUD rendered **ten storage states across four screen sizes** with
no unintended gameplay requests. Raw results are in
[miniature-live-native-verification.json](../../.cache/miniature-live-native-verification.json).
Two initial fixture defects were corrected: a false-positive text assertion and
BindableEvent serialization of a cyclic fake-player table. They are not counted
as passing native runs.

## Deployment status

The first editor sync exposed preserved legacy folders alongside new ones.
Automatic review rejected the proposed broad in-editor cleanup (legacy folders
and non-Terrain/Camera Workspace children), even with a backup. That cleanup was
not executed. The safer deployment path opens the clean reviewed release file
and uses Studio's existing-place save/publish flow; it does not delete old editor
objects individually. The previous editor is not a safe publication artifact
because its inherited startup objects remain.

The clean release file was inspected: one miniature server bootstrap, no legacy
`Game` bootstrap and no FakeProfileStore. Authenticated Studio **Save to Roblox
As** selected the existing private Clash of Civilizations experience and its sole
existing place. Roblox returned **Server is busy and unable to process your
upload request** through multiple automatic retries, ending in **Save failed**.
After closing the previous Team Create editor, the next retry succeeded. A fresh
authenticated EditPlace open independently confirmed saved cloud **version 248**,
the exact authorized place/universe/creator, one live bootstrap, no legacy
bootstrap, no FakeProfileStore and a clean Workspace containing Camera/Terrain.
The previous local file's manual identity metadata was cleared; it is not used as
proof of cloud deployment. A later Studio configuration-fetch 404 on that local
file does not invalidate the independently reopened cloud copy.

The production bootstrap was rehearsed from that actual cloud draft in
**Verification_rehearsal_1793332521422**. Actual LiveStartup reports
`miniature-live-v1` and the isolated persistent adapter; its profile is writable
and the real chooser selected Sparta with the ordinary 200 Coins and three
starter structures. Native W movement and E collected sixty food, Sell All
earned 120 Coins (200→320), and the ordinary 250-Coin training purchase left
70 Coins. A second E collection retained sixty food and the actual inventory
rendered the one held training plan. Stop/restart against the same real isolated
scope created a new session and restored 70 Coins, sixty food, that held plan,
all three building transforms/output and all four workers/assignments. No
balance, health or character-position injection was used. This is a Studio
server restart, not yet a published Roblox-client rejoin. Evidence:
[miniature-production-rehearsal.json](../../.cache/miniature-production-rehearsal.json).
The temporary verification attribute was removed and checked absent afterward.

Creator Hub's actual place Access setting reported a maximum visitor count of
**50**; Studio's separate 60-player value was not the published configuration.
The place limit was changed to **8**, matching the eight plots, and Creator Hub
confirmed **Place access successfully updated**. Private visibility and social
slot defaults were retained. Before publishing, all **106 mapped script sources**
in the cloud editor matched the reviewed release artifact by byte length and
Adler-32, with no missing/unexpected sources and no verification attribute.

Authenticated Studio Publish completed. Creator Hub Version History independently
shows **version 250** with the **Published Version** checkmark (October 29, 2026,
11:59 PM local). Version 248 was the initial clean saved draft; the release is
250. The publication audit screenshot is saved locally as
[miniature-published-version-250.png](../../.cache/miniature-published-version-250.png).
The implementation and rollback backup were committed and pushed in **2da7b0f**.

A separate authenticated Studio **EditPlaceRevision** open explicitly requested
place 73839918762778 / universe 10770758443 / **version 250**. The resulting
historical window is named **Place1 (Version 250)**; its isolated DataModel reports
zero identity/version metadata, so that metadata is not presented as a live-server
version reading. All **106 script sources** nevertheless match the reviewed
release exactly, with no unexpected/missing scripts, legacy bootstrap, fake
store or verification attribute. This independently checks the exact published
revision selected above. Audit:
[miniature-published-source-audit.json](../../.cache/miniature-published-source-audit.json).

The actual installed Roblox client launched the authorized private place through
its normal Play button. It renders the miniature world, outposts, top travel
buttons, inventory hotbar and civilization chooser. The owner-facing Roblox
**Ready to playtest?** notice appears. The client is responsive at the Windows
process level, but desktop automation clicks/key presses did not dismiss that
notice or select a civilization reliably, including standard SendInput events
with confirmed foreground focus. That is not sufficient evidence of a gameplay
input defect; a physical click is needed to distinguish it from automation input
delivery. The user has been asked to check the notice and choose Sparta.
No published-client earning, purchase or leave/rejoin pass is claimed yet.

Existing private visibility is retained, with the confirmed eight-player limit.
The structured [release manifest](../releases/miniature-live-v1.json) distinguishes
saved drafts, publication, native real-storage rehearsal and the remaining
published-client check. Rollback uses the validated fresh backup above; do not
assume an intermediate miniature draft is the old full-size version.
