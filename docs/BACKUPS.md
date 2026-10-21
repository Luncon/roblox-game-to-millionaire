# Pre-redesign checkpoint

Saved before the miniature civilization economy redesign on October 20, 2026.
No redesign gameplay changes have been applied.

- Code checkpoint: `pre-miniature-redesign-2026-10-20`, an annotated tag pushed to GitHub.
- Code commit: `4f3e7a7fc10f61c8b4942cb875ff91e5138a4569`.
- Full Studio place: [pre-miniature-redesign-2026-10-20.rbxl](../assets/place-backups/pre-miniature-redesign-2026-10-20.rbxl), also committed to GitHub.
- Additional local copies: `build/backups/pre-miniature-redesign-2026-10-20/` contains `current-studio.rbxl`, `repository-build.rbxlx`, `source.zip`, `source.bundle`, `checksums.json` and `RESTORE.txt`.

The checkpoint includes existing civilization combat, medics/hospital,
formations, recruitment, minimizable UI and the 50-coin regular earning pad.
The full Studio file also preserves manually imported Workspace content,
including the farmer, horse, water buffalo and mounted models, plus place settings.
The ordinary Rojo build alone does not contain these manual Workspace edits.

## Restore

Open the full `.rbxl` file in Studio to recover the saved place. To inspect the
matching code without discarding subsequent work, create a separate branch:

```sh
git switch -c restore/pre-miniature-redesign pre-miniature-redesign-2026-10-20
```

The local bundle records complete Git history and passes `git bundle verify`.
To recover into a new directory without GitHub access:

```sh
git clone source.bundle restored-game
```

The saved place was reopened in a separate Studio **Edit** session: all 80
production script byte lengths/checksums matched the repository, all ten
Workspace roots and their descendant counts matched the source place, and its
19 equipment, 13 outfit, five NPC and one farmer templates were present.
No playtest or publication was needed for this backup verification.

Player DataStore progress is separate from these project backups. Opening the
local file gives it place ID zero; it does not migrate player storage or overwrite
the published experience.

Full-place SHA-256: `a595187051ee50b9a8901bc130d97c071b57488566d60caf4ac9bf15f81fa0c5`.
