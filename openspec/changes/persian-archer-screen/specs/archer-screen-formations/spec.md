## Purpose

Give Persia a shield formation that establishes a protected archery position and defends locally rather than charging through the center.

## ADDED Requirements

### Requirement: Persian unlocks and selection
Persia SHALL offer Shield Training at settlement/armor 15 after Armorer I for 150 coins and Persian Archer Screen at settlement 20 for 250 after shields, War Council I, Army Camp II and Hospital I. Selection SHALL be faction-isolated under the unchanged version-one fields. Existing Spartan and Roman selections SHALL remain valid.

#### Scenario: Purchase and restore the Persian tactic
- **WHEN** an eligible Persian owner purchases training and selects it at the owned council map
- **THEN** Persian Archer Screen is saved only for Persia and foreign selections are rejected

### Requirement: Straight screen muster and march
The screen SHALL require three living melee, one archer and one medic in camp. It SHALL assemble on the road, then march at six studs per second with three aligned front guards and paired rear supports using supported routes and cohesion gates.

#### Scenario: Deploy the five captured lives
- **WHEN** the ready owner activates March Formation
- **THEN** those five troops walk into the straight screen layout and advance together without teleporting

### Requirement: Bow-range deployment
A marching screen SHALL deploy when its captured archer has a visible valid hostile within 40 studs inside ordinary attack bounds. Deployment SHALL also occur at the final destination if no firing opportunity occurred. Deployed screens SHALL remain positioned after targets move or die until a command or frontline casualty changes the order.

#### Scenario: Stop short to shoot
- **WHEN** a cohesive marching screen reaches a clear bow opportunity before the center
- **THEN** the anchor stops, the archer fires ordinary arrows and the formation remains deployed after that hostile disappears

#### Scenario: Obstructed and protected targets do not trigger deployment
- **WHEN** a target is occluded, friendly, dead, outside combat bounds or beyond 40 studs
- **THEN** it does not cause early deployment

### Requirement: Bounded defense and support
Deployed shieldmen SHALL engage reachable hostiles while staying within six studs of their assigned slots and return to those slots after threats leave. The captured archer SHALL keep its rear slot and ordinary attacks; the medic SHALL heal and avoid enemies. Stationary spear skills SHALL retain normal damage/cooldowns, while formed ranged skills remain excluded.

#### Scenario: Defend the archery position
- **WHEN** a hostile enters a shieldman's local defense area and later retreats
- **THEN** the shieldman attacks within its boundary and returns to its slot while the archer and medic continue supporting

### Requirement: Formation authority and continuity
Advance/Regroup SHALL cancel the screen. Hold SHALL freeze movement while allowing stationary attacks/healing. Frontline loss SHALL release Advance unless explicitly held; support losses SHALL remove only that captured life and replacements SHALL not rejoin stale slots. Lost write authority SHALL force Hold. Sparta and Rome SHALL retain their center-arrival release behavior.

#### Scenario: Cancel or break the screen
- **WHEN** a command, frontline loss or authority loss occurs
- **THEN** the appropriate ordinary order resumes without restoring health, skill cooldowns or pending respawn deadlines
