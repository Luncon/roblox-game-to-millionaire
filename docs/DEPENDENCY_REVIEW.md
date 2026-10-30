# Development dependency review

Reviewed: 2026-10-13. Review again by: 2026-11-13, or before upgrading OpenSpec.

## OpenSpec glob-pattern dependency

OpenSpec 1.14.1 depends on `fast-glob`, which depends on `micromatch` and
`braces`. npm audit reports four high findings along this single dependency
chain for [GHSA-vfj7-8cjw-p6xm](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm).
The advisory describes stack exhaustion from deeply nested brace patterns;
it lists no patched braces version at the time of review.

The affected dependency is used by OpenSpec's local artifact-output globbing.
It is development tooling, not Roblox runtime code. The setup uses the bundled
`spec-driven` schema and trusted local patterns. Do not pass untrusted glob
patterns or install unreviewed external schemas. Review schema changes as code.

The upgrade is deferred because no patched dependency version is available.
npm's proposed forced downgrade to OpenSpec 0.17.2 would replace the selected
workflow rather than provide a compatible patched release. No forced downgrade
or unverified dependency override has been applied.

At the original review, `npm audit` remained nonzero. Recheck it with `npm audit` when reviewing tool
upgrades. This record does not suppress or change the audit result.
Installation scripts remain disabled through `.npmrc`.

## October 28, 2026 tooling setup

`npm ci` and a separate `npm audit` both reported **zero vulnerabilities** with
the existing lockfile. OpenSpec remains 1.14.1; no npm dependency upgrade,
override or lockfile change was made. The earlier finding above is retained as
the historical review rather than the current audit result.

Selene 0.32.0, StyLua 2.6.0 and Lune 0.11.1 are explicit native development
downloads, not npm dependencies. `dev-tools.lock.json` records official GitHub
release URLs and archive SHA-256 digests; the installer verifies these before
extraction into ignored local storage. A clean WSL installation and tool versions
were checked. Windows release digests are pinned but Windows installation was
not executed in this session. Third-party skills are separately pinned and
licensed in [their review record](../.agents/third-party/README.md).
