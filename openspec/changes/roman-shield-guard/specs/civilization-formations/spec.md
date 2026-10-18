## Purpose

Let each supported civilization deploy its own trained formation through the shared council and army controls while preserving faction-isolated progress and combat authority.

## ADDED Requirements

### Requirement: Roman unlocks and selection
Rome SHALL offer Shield Training at settlement/armor 15 after Armorer I for 150 coins, and Roman Shield Guard at settlement 20 for 250 after shields, War Council I, Army Camp II and Hospital I. Its council SHALL select only its own unlocked formation. Existing Spartan purchases and selection SHALL remain valid under the unchanged twenty-field version-one profile.

#### Scenario: Select the Roman formation
- **WHEN** an eligible Roman owner purchases the unlock pad beside the council and selects its map entry
- **THEN** Roman Shield Guard becomes the saved selection, foreign selections are rejected and other civilizations retain independent progress

### Requirement: Compact guard geometry and speed
Roman Shield Guard SHALL require three living melee, one ranged and one medic in owned camp. It SHALL assemble at the road and march at six studs/second, matching Sparta. The center shieldman SHALL lead, the supports SHALL stay together close behind, and outer guards SHALL stand beside them facing partly outward between attacks.

#### Scenario: March a compact guard
- **WHEN** all five required Roman lives muster and March Formation is commanded
- **THEN** all five walk in the compact guard layout with supported routes, cohesion and outward flank facing, without teleporting or slowing relative to Sparta

### Requirement: Roman shield and skill combat
Unlocked Roman players and melee SHALL receive the shared inert two-hit shield with facing-based protection and per-life depletion. Captured formed Roman melee SHALL use unlocked stationary Double Slash without leaving their slots; formed ranged SHALL use ordinary pilum throws without skills. Sources, grips, cooldowns and validated contacts SHALL remain authoritative and unchanged.

#### Scenario: Fight while formed
- **WHEN** a formed Roman shieldman has a valid target and a ready purchased sword skill
- **THEN** two validated stationary slash contacts use the normal cooldown, ranged supports keep ordinary throws, and shield charges are not restored

### Requirement: Shared formation transitions
Both formations SHALL release to ordinary Advance on final center arrival or a captured frontline casualty, unless explicitly held. Hold SHALL retain stationary attacks/healing; Advance and Regroup SHALL cancel formation. Support casualties SHALL remove only that captured life; replacements SHALL NOT join stale formation slots. Lost authority SHALL still force Hold.

#### Scenario: Arrive or lose a front guard
- **WHEN** a marching Roman group arrives at its center destination or loses a captured frontline guard
- **THEN** formation control clears and survivors resume ordinary targeting, movement and medic support while saved selection and independent respawn deadlines remain unchanged
