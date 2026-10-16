# Weapon Skills

## Purpose

Give players and troops shared weapon-family attacks with paid ten-level progression milestones and authoritative, bounded combat.

## ADDED Requirements

### Requirement: Weapon family eligibility
Skills SHALL follow the actual wielded weapon: spear/javelin grants Dash Thrust, axe grants Whirlwind, and swords including sabre, katana, rapier, khopesh, gladius, kilij and dao grant Double Slash. Eligible owned players and troops SHALL share purchased progression regardless of civilization or troop class. Unsupported weapons and neutral actors SHALL receive no skill in phase one.

#### Scenario: Cross-class eligibility
- **WHEN** a ranged javelin or throwing-axe troop has a valid close-range opportunity and its owner has purchased the skill
- **THEN** it can use its weapon-family skill without gaining player ranged attacks
- **AND** its ordinary projectile and skill actions cannot overlap

### Requirement: Paid skill tiers
Skill tiers I–V SHALL require weapon levels 10/20/30/40/50 and owned Training Yard I, costing 100/200/350/550/800 coins respectively. Tiers SHALL be purchased sequentially per civilization; meeting a threshold alone SHALL NOT grant the skill. The same tier SHALL apply to all eligible weapon families in that civilization.

#### Scenario: Purchase and preservation
- **WHEN** an eligible owner buys the next skill tier
- **THEN** the exact price is deducted once and matching living/replacement units receive the tier
- **AND** health, existing cooldowns, army slots and pending respawn deadlines remain unchanged

### Requirement: Training camp purchase pad
Only the next eligible skill tier pad SHALL appear beside the training camp. Its label SHALL show skill, tier, price and effect; affordability SHALL use existing pad colors. Locked and completed pads SHALL be absent. Purchase SHALL validate owner, claim, distance, prerequisites, funds, authority and contact latch on the server; workshop discounts SHALL NOT apply.

#### Scenario: Ineligible pad interaction
- **WHEN** a foreign player, repeated body contact or a non-writable owner attempts a purchase
- **THEN** no duplicate or unauthorized purchase occurs

### Requirement: Dash thrust
Dash Thrust SHALL have an eight-second cooldown, begin immediately and travel at most twelve studs over 0.20 seconds, stop at obstacles and strike only the first hostile in its path. Tier damage SHALL be 130/140/150/160/170 percent of the wielder's ordinary single-hit damage. It SHALL remain grounded inside the battlefield and grant no stun or invulnerability.

#### Scenario: Blocked dash
- **WHEN** a dash meets a wall or arena boundary before an enemy
- **THEN** movement stops safely with no attack through the obstacle or boundary
- **AND** the activation cooldown remains spent

#### Scenario: Forward spear dash presentation
- **WHEN** a player or owned spear/javelin/pilum troop dashes
- **THEN** its spear tip stays level and pointed in the thrust direction while its torso leans forward, its hand extends and its legs form a driving lunge
- **AND** a short tapered tip trail emphasizes travel, without changing grips, source templates, collision, damage or action timing
- **AND** the pose and owned trail attachments release on action completion or cancellation

### Requirement: Whirlwind
Whirlwind SHALL begin immediately, complete its spin in 0.35 seconds, have a twelve-second cooldown and strike at most three distinct hostiles within six studs once each. Tier damage per target SHALL be 80/90/100/110/120 percent of ordinary single-hit damage. Each hit SHALL require battlefield protection and visibility checks.

#### Scenario: Crowded spin
- **WHEN** more than three enemies surround an axe wielder
- **THEN** only the three nearest valid visible hostiles can take damage, once each
- **AND** friendly, protected and wall-obstructed actors take none

### Requirement: Double slash
Double Slash SHALL have a nine-second cooldown and an immediate first strike and a second strike approximately 0.24 seconds later at action completion, with broad opposing arm cuts and torso rotation against one target. Tier damage SHALL be 65+75/70+80/75+85/80+90/85+95 percent of ordinary single-hit damage. Each strike SHALL independently validate reach, facing, visibility and target life; neither SHALL stun or retarget another enemy.

#### Scenario: Enemy escapes combo
- **WHEN** the target leaves reach, dies or becomes protected after slash one
- **THEN** slash two misses without transferring to another target or life

### Requirement: Activation and combat authority
Accepted activation SHALL start cooldown even if it misses and exclude ordinary attacks throughout the active animation, without a startup or recovery pause. Ordinary movement and attacks SHALL resume at action completion. Damage SHALL use activation-time tier and ordinary role damage, including the ranged multiplier for ranged actors. Server validation SHALL own eligibility, movement, targets, hits and exactly-once life rewards. Skill hits SHALL NOT recursively proc extra attacks.

#### Scenario: Duplicate or canceled activation
- **WHEN** a duplicate request arrives or the actor dies, switches civilization, loses authority or starts Regroup during a skill
- **THEN** no duplicate contact occurs and invalid pending movement/hits are canceled
- **AND** cooldown cannot be reset by a purchase, character reset or civilization switch within the server

### Requirement: NPC tactics and player controls
Players SHALL have keyboard, touch and gamepad skill controls with tier/readiness feedback. NPCs SHALL activate automatically only for valid opportunities. Hold SHALL prohibit dash movement and permit stationary skills only against in-range enemies; Regroup SHALL prevent skill use and cancel pending contacts. Animation SHALL preserve equipment grips and imported source rigs.

#### Scenario: Holding spearman
- **WHEN** a spear troop is holding position with a ready dash
- **THEN** it remains stationary and does not dash

#### Scenario: Accepted player activation is visible
- **WHEN** a living equipped player activates an unlocked skill with R
- **THEN** the cosmetic pose starts immediately on eligible local input and the server-approved skill animates on their R6 or R15 character even when the acceptance arrives after the server action deadline
- **AND** ordinary animation tracks cannot mask the skill, rest joints and equipment grips remain intact, and movement/attack locks end with the active action

#### Scenario: Delayed visual start and rejected preview
- **WHEN** a start message arrives after the short server action has finished, or a local preview is rejected
- **THEN** an observer still sees one complete local animation, an already completed local preview is not replayed, and a rejected preview releases immediately
- **AND** no preview or visual deadline can authorize movement, damage, cooldown resets or overlapping ordinary attacks

### Requirement: Independent skill persistence
Purchased skillLevel SHALL save independently per player and civilization, with missing-only default zero. Explicit invalid tiers or unmet weapon/training prerequisites SHALL block unsafe loading. Existing fourteen scalar fields and profile keys SHALL remain intact; cooldowns and attack state SHALL NOT save across servers.

#### Scenario: Legacy restoration
- **WHEN** an old profile loads, purchases a skill and later rejoins
- **THEN** its original progress is preserved, the purchased tier restores, and other civilizations retain independent skill progress
