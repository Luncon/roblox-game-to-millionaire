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
Formed troops SHALL retain validated stationary attacks and healing while suppressing independent pursuit, optional footwork and automatic dash skills. Medic enemy avoidance SHALL remain available. Advance SHALL immediately abandon formation and restore independent combat; Hold SHALL stop movement while allowing attacks/healing; Regroup SHALL cancel formation and return to camp.

#### Scenario: Abandon a formation
- **WHEN** the owner presses Advance during road assembly, marching or formation Hold
- **THEN** formation goals and reservations clear immediately, selection stays saved and troops resume normal behavior without changing health or respawn timers

### Requirement: Fresh lives and authority
A lost member, changed claim, disconnected owner, invalid authority or teardown SHALL stop stale formation control. Surviving members SHALL Hold after a casualty; replacements SHALL NOT automatically join a prior march. A new march SHALL require a fresh complete camp muster. Shield breakage alone SHALL NOT scatter the formation.

#### Scenario: Member dies
- **WHEN** a formed troop dies and a replacement later spawns
- **THEN** remaining troops stop the old march and no replacement is assigned stale movement
