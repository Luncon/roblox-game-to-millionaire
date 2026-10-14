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

`npm audit` remains nonzero. Recheck it with `npm audit` when reviewing tool
upgrades. This record does not suppress or change the audit result.
Installation scripts remain disabled through `.npmrc`.
