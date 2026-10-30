---
tags: [roblox, miniature, interface, implementation]
updated: 2026-10-29
---

# Miniature UI implementation

Latest revision: [Simple Shop and Automatic Troops](Simple%20Shop%20and%20Automatic%20Troops.md)
records the current research-free shop, automatic building-owned groups under ten
and expanded map. Older research/inspection/roster milestones below are history.


Current interaction revision: [Inventory and Shared Shops](Miniature%20Inventory%20and%20Shared%20Shops.md)
replaces manual assignment/hiring, Move/Unpack/collection buttons and material
purchase costs with automatic civilians, a building-item hotbar/hammer, world E
collection, shared stalls and Coin-only prices. Production is ten times faster
for testing. Native acceptance of this revision passed and is tracked in task group9; older
milestones below describe the previous interaction contract.


The separate fake-store miniature sandbox now has a first client implementation. The original miniature art preview and production game remain separate. The approved direction is in [[Miniature Civilization Redesign]] and the implementation requirements remain in `openspec/changes/miniature-civilization-redesign/`.

The interface uses dark stone, wood, warm parchment, gold and terracotta. It adapts the reference game's practical resource, merchant and research hierarchy into native Roblox controls. Merchant previews use the active civilization's actual model kit. All thirteen civilization identities and their historical periods remain visible; server-supplied kit availability controls which are playable and pending kits are explicit.

The first playable loop is: choose Sparta, approach its grain farm, inspect and collect ten grain, approach the Council Courtyard, open Trade and sell ten for twenty coins. The server owns all balances, claims, production and purchases. Client receipts carry the current authority context and revision. Requests are serialized, never automatically retried after timeout, and do not optimistically change goods or coins.

Implemented client surfaces include settlement resources and worker counts, merchant categories and plan placement, building inspection and worker assignments, collection and trade, three connected research branches with a text-list alternative, research services and reserves, and a training roster. Army units in this slice are presentation only. Plans, workers and research remain separately paid; research does not grant buildings for free. Merchant stock renews on its ordinary three-minute cycle.

Walk and Overview remain available independently of minimized panels. Each panel uses the existing session-only `PanelVisibility` behavior. Quantity, reserve, branch, category and roster drafts survive minimization. Hidden panels continue evaluating life, range and authority. Placement uses a local snapped footprint, rotation and an explicit confirmation; only a successful server receipt commits the change. A claim change or respawn clears placement.

The responsive shell supports the target 320×360, 320×568, 640×360 and 1024×768 sizes with scrolling content and primary targets of at least 44 pixels. Text labels accompany unavailable states; color alone does not convey placement validity or research status.

## Verification milestone

Client modules pass the pinned StyLua formatter and Selene with zero errors or warnings. `tests/miniature-game/Input.luau` provides a native Studio Client fixture for explicit Sparta selection, a real world farm click, Collect 10, Sell 10, and the four layout sizes. It also checks ordinary W-key movement, Walk/Overview camera switching and wheel zoom. The fixture also checks independent HUD/Trade minimization, retained quantity drafts and distance revalidation while hidden. An optional `editFlow=true` adds native plan purchase, placement cancellation, R-key rotation and confirmation. Physical relocation used to isolate interaction checks remains fixture setup; the separate W-key assertion tests walking. Native execution and visual review are still required; an automated build is not evidence that the interface works in Roblox.

Stable native check names include `MiniatureSandboxHUD`, `SettlementHUD`, `Select.Content.SelectSparta`, `Inspector.Content.Collect10`, `Trade.Content.Sell10`, and `SettlementHUD.Navigation.TradeNavigation`.

All thirteen prototype art kits are delivered, with source cards and native evidence sheets. The sandbox has no real-player storage access, live rollout, combat or healing. Historical uncertainties remain labeled; prototype delivery does not certify every costume or building as a reconstruction.

## First native pass — 2026-10-29

The isolated Studio client passed native virtual-input selection, farm world inspection, Collect 10, Sell 10, W-key movement, Walk/Overview and wheel zoom, independent minimization with retained drafts and hidden distance guards, and house-plan purchase/cancel/rotation/confirmation. The run also passed the four bounded Frame layout checks. The observed initial coin path was 200 → 220 after the grain sale → 140 after the house plan. These are Studio virtual-input observations, not a physical-phone, controller or published-client test.

The research interface now retains pan and selected nodes across tree/list switching and remembers a selection per branch. Explicit pan arrows supplement native dragging/scrolling, and zoom controls preserve tree position. Every node labels Locked, Available, Researching or Completed; details and the equivalent list include the improved-council requirement, predecessor, exact cost, active duration and numeric effects.

The extended native fixture accepts `{editFlow=true, nativeResearchInput=true}`. Research presentation fixtures exercise mixed completed/researching/locked states, available-state transitions, all nine effect descriptions, native pan/zoom/branch/list/node clicks and confirmation bounds at all four layouts. These isolated client render states never change authoritative snapshots or send research transactions. The integrating agent subsequently recorded the extended native pass and screenshot below; OpenSpec task 6.2 is complete.


October 29 extended native result: all four research presentation layouts passed
with actual pan/zoom/node/branch/list input, exact nine-node details, status labels
and retained selection. See the [native screenshot](../assets/miniature-research-native-2026-10-29.jpg)
and [fixture evidence](../assets/miniature-native-2026-10-29.json). These local
render states do not establish server research completion; that belongs to the
advanced gameplay fixture.


The available-kit map now comes from the server; selector availability and model
previews follow it. The active civilization supplies house/building and troop
role names. Army cards preview the same three inert role figures as the world;
these labels and figures add no combat or healing capabilities. Thirteen native
kit factories passed their native contracts and the all-thirteen claimed-plot UI
tour; their visual evidence sheets are linked from the vault index.

## Respawn movement regression — 2026-10-29

The native lifecycle run preserved the settlement, invalidated the old claim epoch,
cleared the placement draft and restored the Walk camera to the new Humanoid, but
the new commander did not move. The user also confirmed that physical W input
failed. This is a real movement regression, not an automation-only failure. The
living, unanchored commander retained speed 16; default PlayerModule controls
reported enabled and referenced the new Humanoid. All five default movement and
jump bindings remained present, while a held W reached UserInputService without
changing the default controller's movement vector.

The sandbox now includes a narrow `Movement` adapter that waits for the current
character, Humanoid, root and default PlayerModule, allows its initialization to
finish, then disables and enables those default controls to refresh their bindings.
Old-character callbacks and destroyed interfaces are guarded. The adapter adds no
custom movement keys or movement callbacks and changes no stats or server authority.
Pinned formatting and lint pass. On the same blocked native client, installing the
adapter refreshed the default bindings once and the W-key test then moved the
commander 15.9998 studs, compared with zero before the refresh. No Humanoid stats,
physics flags or direct movement callbacks were changed.

The subsequent full native lifecycle rerun passed after another explicit
server-side death. The fresh commander walked 15.99976 studs with zero vertical
change and MoveDirection `(0, 0, -1)` after the automatic CharacterAdded refresh.
The Walk camera used Custom mode and the new Humanoid. Coins stayed 4,920, the
held house plan stayed at one, the old placement ghost was cleared and clicking
the former confirmation location sent no request. The same saved session and
plot survived while the claim epoch advanced from 5 to 8. This verifies the
automatic respawn hook in the owned Studio run; physical phone input and a
published client remain separate checks.

## Physical keyboard confirmation — ordinary build

The user subsequently reported no movement in `miniature-playtest.rbxlx`.
Read-only live inspection found an alive, unanchored commander, Walk camera,
enabled default Keyboard controller, one initial binding refresh, no focused
text box and no modal GUI buttons. Temporary input logging changed no bindings.
After the game view gained focus, the user's physical W reached the default
controller (`forwardValue=-1`, movement vector `(0,0,-1)`) and moved the commander
about9.87 studs, from Z133 to123.13. Key release returned movement to zero.
The user confirmed “i can move now.” No additional movement code was changed.
This confirms physical desktop keyboard movement in the ordinary build after
viewport focus; phone/controller and published clients remain separate checks.
See the [physical input trace](../assets/miniature-physical-keyboard-2026-10-29.json).


## Controller-context isolation during inventory acceptance

The inventory respawn check exposed a test-harness defect. Requiring PlayerModule
from ExecuteLuau's tool context creates a different singleton from the one loaded
by actual LocalScripts. A temporary actual LocalScript and tool probe reported
separate controller/keyboard identities: the game controller received W while the
tool controller stayed zero and the Humanoid did not move. The second singleton
replaced the same named ControlScriptRenderstep binding. See the
[context evidence](../assets/miniature-controller-context-2026-10-29.json).

Earlier binding resets and a candidate direct-KeyCode shim masked this fixture
interference. They were removed; native fixtures must not require
PlayerModule from the tool VM. Normal Roblox controls own movement, camera and
respawn. Actual horizontal displacement and Humanoid.MoveDirection establish the
movement result without creating another controller. The user's earlier physical
keyboard confirmation remains valid; phone/controller/publication are separate.


A fresh ordinary controller also exposed a device-readiness race: controls were
enabled with the correct Humanoid and KeyboardAndMouse preference, but no active
controller or movement bindings were selected. In an actual LocalScript,
UpdateMovementMode selected the ordinary keyboard controller and restored15.9997
studs of movement. The user confirmed physical W now moved. InputReadiness now
refreshes that default selection at startup, device-capability changes and fresh
character readiness without Disable/Enable or custom bindings. The final native
inventory/guard run passed16.2664studs after a real death, preserved160 Coins,
48 Grain/one held house/eight civilians/four buildings, and cleared selection and
ghost. The0.4-stud vertical change was the normal raised-plot step; the assertion
measures horizontal movement. See the [final receipts](../assets/miniature-inventory-final-2026-10-29.json).
