# Installed third-party skills

Installed October 28, 2026 using Codex's skill-installer helper. These are
project-local snapshots; updating them requires review rather than a live fetch.

| Source | Revision | Installed skills | License |
| --- | --- | --- | --- |
| [afrxo/roblox-agent-skills](https://github.com/afrxo/roblox-agent-skills/tree/ff50be7a8a000a24c0f85254e1747a0eb35d857f) | `ff50be7a8a000a24c0f85254e1747a0eb35d857f` | luau-expert, roblox-dev, roblox-toolchain, roblox-ui | [MIT](roblox-agent-skills.LICENSE) |
| [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman/tree/9b68f7ed12b05e7efaff18e65c5a3fc2849fd0a4) | `9b68f7ed12b05e7efaff18e65c5a3fc2849fd0a4` | caveman (core voice skill only) | [Apache-2.0](caveman.LICENSE), [MIT](caveman.LICENSE-MIT) |

Roblox skill examples and references are retained unchanged. Their shared
[integration policy](../shared/integration-policy.md) is installed at the relative
path their SKILL.md files expect. Upstream examples describe preferred patterns,
not verified project APIs: repository instructions, pinned tools and official
documentation take precedence. For example, verify language claims such as
`const`, `unknown`, and removal of `getfenv` before using them; installing a skill
does not establish that those claims work in this project's Luau runtime.

Caveman is available on demand and is not activated by installation. Its upstream
README also describes sibling skills and host hooks that are not installed here.
No upstream install scripts, proxies, hooks, account integrations or services
were executed or enabled.
