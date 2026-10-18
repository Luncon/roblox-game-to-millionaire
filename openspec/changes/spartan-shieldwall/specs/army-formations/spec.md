## Purpose

Let an owner choose a trained formation at a physical council table and explicitly deploy a complete army from camp into coordinated battlefield movement.

## ADDED Requirements

### Requirement: Physical council selection
The owned War Council map table SHALL offer formation selection through an interaction usable on keyboard, touch and controller. Selection SHALL require a living nearby owner, writable progress and a purchased eligible formation. The HUD SHALL provide a separate March Formation command and readable missing-requirement feedback.

#### Scenario: Reject remote or foreign selection
- **WHEN** a player requests a locked, foreign or distant council selection
- **THEN** selection and currency remain unchanged

### Requirement: Complete camp muster
March Formation SHALL require a selected Spartan Shieldwall and exactly its five living owned members: three melee, one ranged and one medic, physically within the owned training camp at ground height. Client-provided positions, readiness, ownership or slot assignments SHALL NOT authorize deployment.

#### Scenario: Missing patient or wrong camp class
- **WHEN** the medic is outside camp, a member is dead or the selectable camp slot is ranged
- **THEN** the command identifies the missing condition and no formation march begins

### Requirement: Road assembly and coordinated march
A validated group SHALL gather at server-chosen positions centered on the road outside its settlement and wait for all members before advancing. Marching SHALL retain a shallow convex front with the middle melee leading the outer two and ranged/medic side by side behind, matching `(:` when travelling left. Troops SHALL walk supported routes without teleports or crowding, and pause for lagging members.

#### Scenario: Slow arrival
- **WHEN** one member has not reached its road position
- **THEN** the front does not advance without it

### Requirement: Formation combat and interruptions
Formed troops SHALL retain stationary attacks, healing and medic enemy avoidance while suppressing independent pursuit, optional footwork and dashes. Advance SHALL abandon formation immediately; Hold SHALL stop movement but permit attacks/healing; Regroup SHALL cancel formation and return to camp.

#### Scenario: Abandon a formation
- **WHEN** the owner presses Advance during road assembly, marching or formation Hold
- **THEN** formation goals and reservations clear immediately, selection stays saved and troops resume normal behavior without changing health or respawn timers

### Requirement: Stationary frontline skills
Eligible captured Spartan melee SHALL use a stationary spear thrust within ordinary melee reach, including formation Hold. It SHALL preserve purchased skill damage, one validated contact, ordinary-attack exclusion, duration and cooldown, with no dash/trail and planted-leg animation. Formed ranged SHALL use ordinary attacks without skills. Lost membership, Regroup, death or authority loss SHALL cancel formation skills.

#### Scenario: Thrust without leaving the shield line
- **WHEN** an eligible captured front-line spear troop has a visible hostile within melee reach and its skill is ready
- **THEN** it performs one stationary skill thrust without leaving its slot or replenishing shields, while ranged supports keep ordinary attacks and the group retains cohesion

### Requirement: Destination combat release
Reaching the final center march destination SHALL dissolve formation and resume ordinary Advance for all surviving troops, regardless of enemy positions or attack range. Explicit Hold SHALL freeze the march until another command. Shield breakage alone SHALL NOT scatter a marching or held formation.

#### Scenario: Arrival releases ordinary combat
- **WHEN** an intact formation reaches its final center march destination
- **THEN** formation control clears and survivors resume ordinary Advance, independent targeting and medic support without requiring a casualty or manual command

### Requirement: Frontline casualty release
A lost captured front-line melee life SHALL clear the formation and release survivors to ordinary Advance, unless the owner explicitly commanded Hold, in which case survivors SHALL stay on Hold. Saved selection, spent shields and independent respawn deadlines SHALL remain unchanged.

#### Scenario: Front-line member dies
- **WHEN** a formed front-line melee troop dies and a replacement later spawns
- **THEN** survivors resume ordinary Advance, independent targeting and medic support, selection remains saved, and no replacement is assigned stale formation movement

#### Scenario: Explicit Hold survives a casualty
- **WHEN** the owner commands Hold and a formed front-line melee troop dies
- **THEN** the formation clears but survivors stay on Hold and continue nearby attacks and healing

### Requirement: Support losses and fresh lives
Lost ranged or medic lives SHALL leave the captured formation while the surviving shield line continues. Replacements SHALL follow the current ordinary order and SHALL NOT join a prior formation. A new march SHALL require a fresh complete camp muster.

#### Scenario: Support casualty preserves the shield line
- **WHEN** a captured ranged or medic life is lost or replaced
- **THEN** that life leaves the formation, surviving members continue marching or deployment, and the replacement is not enrolled into the old formation

### Requirement: Authority cancellation
Changed claims, disconnected owners, invalid authority and teardown SHALL stop stale formation control. Lost write authority SHALL force Hold.

#### Scenario: Write lease is lost
- **WHEN** an owner loses writable profile authority during a formation march
- **THEN** the formation clears and surviving troops stop on Hold without an automatic Advance transition
