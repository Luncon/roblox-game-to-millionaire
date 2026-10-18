# Design

## Context

See proposal.md. FormationConfig currently describes Sparta alone, and purchase/profile/council/shield/skill code compares that identity directly. WarriorService captures five lives and delegates geometry to ArmyFormation; its pending continuity changes already release center arrivals and front-line casualties while preserving support-loss and explicit Hold behavior. TycoonButtons validates physical interactions and Economy owns all balances.

## Goals / Non-Goals

**Goals:** Add a second concrete formation without duplicating the coordinator, keep current saved fields/Spartan behavior, make Roman support protection visibly different, and fund normal Studio testing through server-owned physical interactions.

**Non-Goals:** A generic formation editor, new shield assets, overhead defense, passive stat multipliers, live cheats or new save keys.

## Decisions

- FormationConfig keeps shared progression/pace/roles and holds frozen faction definitions addressed by id or civilization. ArmyFormation captures the selected definition with its current lives; offsets, minimum shape bounds and idle guard headings come from it. Use explicit definitions rather than a second coordinator or arbitrary client offsets. Roman offsets put the center five studs ahead, flank guards at +/-5.5, and supports at +/-1.75 only 1.5 behind the outer guards. Both formations retain pace six and normal terrain/cohesion gates.
- Expose the faction definition to progression titles, profile validation, economy selection, council UI and miniature map markers. Reuse shieldLevel/formationLevel/selectedFormation per civilization, preserve all twenty fields and version-one keys, and reject an id belonging to another civilization. Mirror existing unlock prices and prerequisites rather than inventing a second progression track.
- Expand existing per-life shield eligibility to Sparta and Rome. Both use the same sanitized inert shield asset on player/melee rigs. Preserve the existing per-life remaining-charge attribute so rebuilding or switching cannot refill a life. Actual root facing determines accepted blocks; outward Roman guard headings apply between attacks while ordinary aiming still faces the enemy. No shared damage aura or invisible wide block arc.
- Server encounter options mark captured formation members. WeaponSkillService accepts only the definition's stationary family: spear for Sparta and sword for Rome. Roman Double Slash uses existing immediate/second-contact timings, damage and cooldown with no root travel. Ranged formation members skip skill dispatch. Hold and cancellation retain normal action locks and authority checks.
- Add a Studio-only test pad entry beside CoinButton. BattlefieldMap filters its creation/visibility by RunService:IsStudio. TycoonButtons supplies existing owner/life/proximity guards and calls a fixed-amount Economy method, which independently rejects non-Studio, lost write authority, insufficient cap headroom and rapid repeats. Add an injected environment predicate for deterministic fake tests; production uses the real RunService check. Do not expose any new earning remote or accept amounts from clients.

## Risks / Trade-offs

- Compact supports can fight local spacing -> keep all planned root distances above three studs and test actual five-body road/march and medic avoidance.
- Outward facing can conflict with attack aiming -> use the guard heading only between active attacks, leaving locked attack facing intact.
- Generalizing save validation could accept foreign unlocks -> test legacy Spartan records, Roman round trips, invalid ids and unrelated civilizations before native purchase checks.
- Test grants can accidentally become live cheats -> independently gate economy and pad creation, test disabled mode and lease loss, and retain normal currency cap/save publication.

## Migration Plan

Verify the pending Spartan/sight baseline in one fake-store Studio Play. Implement faction definitions/progression, Roman movement/combat, then the test pad in bounded slices with deterministic checks. Run the expanded native fixture for physical purchases, council selection, shield visibility/depletion, unanchored marching, stationary sword skills, center/casualty/Hold transitions and test grants. Refresh normal/manual builds, sync repository sources into the main Edit place, record evidence and close the owned test window. No real player storage fixture or Roblox publication is authorized; no teleport changes require published-client tests. Rollback removes Roman selection/grants while retaining existing version-one progress fields and never replacing a failed load.
