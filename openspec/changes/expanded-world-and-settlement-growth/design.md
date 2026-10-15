# Design

## Context

The existing map uses 60–84 stud plots on a 160-stud ring, a 150-stud combat
cylinder, hardcoded roads and four-stage construction. Dwelling placement repeats
coordinates above level four, and exact-level cosmetics disappear at later
levels. Profile validation hardcodes four while Economy reads track lengths.
See proposal.md and the three capability specifications for the outcome.

## Goals / Non-Goals

Support deterministic gradual growth, safe saved-state compatibility and real
NPC movement in the expanded owned world. This iteration uses generated stylized
geometry, preserving foreign Workspace/Terrain content. It adds no terrain-editor
workflow, new matchmaking, formations or extra living troop slots.

## Decisions

- Shared configuration sets 50 settlement/weapon/armor levels, a 60-stud starter
  footprint and four studs of width per level: final width 256. Eight centers on
  a proposed 560-stud ring have approximately 428.6 studs between neighbors;
  conservative full-plot circumscribed bounds leave about 66.5 studs. A 500-stud
  diameter battlefield and 1600-stud square ground leave space for scenery.
  Final measurements and real travel, not this estimate alone, are acceptance
  evidence. Smaller 160-stud capitals were considered but leave less room for
  the requested magnificent final settlements.
- Separate owned landscape geometry creates five biome regions, shallow water,
  dry crossings and varied outskirts. Critical routes remain dry and low; central
  combat surfaces remain within the existing vertical damage tolerance. Decoration
  has explicit bounds and avoids reserved plots/lanes. Global Terrain clearing
  was rejected because it would overwrite developer work.
- Construction keeps an invariant starter core, forecourt, barracks and exits.
  Stable deterministic expansion lots and civilization-specific landmarks add
  detail at each level. Reuse existing pieces on consecutive growth where safe;
  civilization switches and transformed rebuilds reconstruct deterministically.
  Target no more than 400 static BaseParts per finished settlement; measure the
  eight-capital fixture and record limitations before claiming device performance.
- Damage = 10 + 8*(level-1)/49; health = 100 + 40*(level-1)/49. Fractional
  stats remain authoritative through melee, ranged and replicated equipment.
  Current 10–25/100–170 endpoints were considered: maximum versus starter hit
  counts were 4 versus 17. The chosen endpoints give 6 versus 14, without
  claiming this stationary comparison proves live balance.
- Proposed next settlement cost = 25 + 10*(currentLevel-1); weapon/armor cost =
  15 + 3*(currentLevel-1), with no next cost at 50. Total progression cost is
  12,985 settlement plus 4,263 per gear track. One coin per activation and ten per
  final hit remain unchanged. Prices are prototype tuning, not new timers.
- Retain early physical tier pads, then show one stable next-level weapon and
  armor pad for levels above four. They display settlement locks and current
  costs without creating 98 simultaneous pads or resetting touch-entry latches.
  Move barracks-IV pad inside the smaller gradual level-four footprint. Barracks
  remains four levels with its current 15→13.5 second delays and two slots.
- Profile schema version, DataStore names/scopes and numeric levels remain intact.
  Validate each field against its own track length and settlement cap. Existing
  tier four is retained numerically and explicitly rebalanced; mapping it to 50
  would grant all new progression for free. No fresh store or silent resets.

## Risks / Trade-offs

- Longer marching distances → verify measured real arrivals from small, middle
  and final settlements and ensure dry, comparable routes; avoid maze scenery.
- Fractional stat comparisons → test with tolerances and preserve class factors;
  do not floor ranged gains away.
- More geometry and growth work → measure part counts/build time and inspect
  completed cities; do not claim mobile frame rates from a Studio desktop run.
- NPC arrival on vertically separated geometry → require height as well as XZ
  arrival and keep critical paths on supported low surfaces.
- Previously earned level-four gear becomes weaker → preserve progress and coins,
  document the curve change, and apply the same curve to all civilizations.

## Migration Plan

Deploy the same production project and restart Play. Existing version-one saves
remain readable; new level-50 states extend validation without renaming keys.
An old four-level build cannot safely read newly saved high levels: rollback
requires retaining the widened validator or a forward-compatible build, never
clamping or overwriting stored progression. Automated fixtures use fake storage.
Studio verifies geometry, visuals, inherited equipment, native pads, navigation
and saved restoration; public Roblox/hardware performance remains separately
unverified unless actually observed.

References: Roblox [pathfinding](https://create.roblox.com/docs/characters/pathfinding)
documents its 3,000-stud request and 20,000-node limits; the
[Humanoid API](https://create.roblox.com/docs/reference/engine/classes/Humanoid)
accepts numeric health and damage. Long routes need measured engine checks even
when their straight-line distance is below the documented cap.
