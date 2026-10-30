# User-supplied mount models

Imported from the user's `miniature-smooth-army-playtest.rbxlx` workbench on
2026-10-29. The raw eleven-model pack is preserved at
`mount-source-backups/user-imports-2026-10-29.rbxm`; this directory is never mapped
into gameplay. Original workbench scripts were disabled after the raw backup.

Only `mount-templates/*.rbxm` is mapped, under ServerStorage.MountTemplates in the
miniature gameplay project. The production/default project and clean scale
preview do not receive these assets. Template keys are bear, bull, camel,
crocodile, elephant, elk, horse, lion, rhino, tiger and wolf. Persia derives its
leopard from a cloned tiger; British/Mongol horses share geometry with distinct
scale, rider and decoration. All thirteen role identities are in
[MountConfig](../prototypes/miniature/game/shared/MountConfig.luau).

The [import audit](../docs/assets/miniature-mount-import-audit-2026-10-29.json)
records original names, part counts, animation IDs and script conflict categories.
Thirty-two imported scripts total 47,410 characters. They include four damage
handlers, ten touch handlers, player riding/input code, physics movers, sound and
replacement logic. No external require/loadstring/HTTP/DataStore calls were found.
All executable code, remotes, seats, physics controllers, Humanoids/Animators and
animation-editor values were removed from gameplay exports; their contents remain
in the raw archive. Four seat parts were omitted, leaving 523 original parts in the
eleven inert templates. No source geometry was replaced with a placeholder.

At runtime only fresh clones are reshaped: invisible control proxies and old
rigging are removed, anatomy is grouped into game-controlled joints, and the
original civilization rider is attached. Never mutate templates to animate or
decorate a troop. The original uploaded animation IDs are provenance, not a
requirement to execute third-party controllers or use permission-limited tracks.

`node scripts/run-lune.mjs .lune/mount-assets.luau` deserialises the binary assets
as data and verifies all eleven inert templates, 523 parts and the complete raw
backup with 527 parts/32 scripts. It never compiles or runs imported Script.Source.
This check is also part of `npm run check:miniature`.
