# Spec Delta

## Purpose

Make NPC battles readable and tactical through coordinated positioning, deliberate targeting and visible attacks for owned and neutral combatants.

## ADDED Requirements

### Requirement: Melee engagement spacing
Advancing melee troops SHALL take distinct available positions within melee reach, steer away from nearby bodies and wait or choose another enemy when positions are occupied. Owned troops and neutrals SHALL follow the same positioning rules.

#### Scenario: Several troops engage one enemy
- **WHEN** multiple unanchored melee troops approach the same target
- **THEN** they occupy separate approaches and settle into attacks without sustained torso overlap or endlessly circling

#### Scenario: Crowded or coincident starts
- **WHEN** attackers outnumber available positions or start at the same point
- **THEN** movement uses finite deterministic directions and overflow attackers wait or select an available opponent

### Requirement: Deliberate target selection
NPCs SHALL retain a valid target through small distance changes, replace invalid targets and consider nearby threats to friendly ranged troops and already crowded targets when choosing an opponent.

#### Scenario: Protect the backline
- **WHEN** a hostile approaches a nearby friendly ranged troop while a melee troop chooses a target
- **THEN** the melee troop favors intercepting that threat over an otherwise similar distant opponent

#### Scenario: Enemy crosses or dies
- **WHEN** another enemy becomes slightly closer or the current enemy dies
- **THEN** the troop respectively retains the valid opponent or selects a new valid opponent

### Requirement: Timed server attacks
NPC attacks SHALL visibly wind up, make one contact attempt and recover. The server SHALL validate the locked target, hostility, arena, range, visibility and current authority at contact before damage or projectile release. An interrupted or missed attack SHALL cause no damage.

#### Scenario: Target escapes a swing
- **WHEN** a target leaves reach, becomes protected, dies or becomes obstructed during windup
- **THEN** the strike causes no damage and does not silently hit a replacement target

#### Scenario: Valid contact
- **WHEN** a strike reaches a still-valid target
- **THEN** it applies at most one normal damage event, or releases one normal nonhoming projectile, and observes the existing attack cooldown

### Requirement: Ranged positioning
Advancing ranged troops SHALL hold a useful firing distance, make bounded slower retreats from close melee threats and seek a nearby clear firing line when obstructed. Aiming and release SHALL stay stationary; recovery MAY permit guarded optional strafing before the next shot.

#### Scenario: Melee approaches an archer
- **WHEN** an advancing enemy gets dangerously close
- **THEN** the archer takes limited arena-safe backward steps, stops when safe or blocked and remains catchable by melee

#### Scenario: Obstructed or edge position
- **WHEN** a shot is blocked or a proposed retreat crosses an obstacle or arena edge
- **THEN** the troop seeks a safe local alternative or waits without firing through geometry or leaving the battlefield

### Requirement: Weapon-specific combat presentation
Troops SHALL show weapon-appropriate preparation, contact and recovery poses with body facing and brief accepted-hit feedback. Spear thrusts, blade or axe swings and ranged aim/release poses SHALL be visibly distinguishable on generated and imported rigs without changing source appearance.

#### Scenario: Watch a close exchange
- **WHEN** a player observes moving troops with different weapon roles
- **THEN** the visible weapon motion matches the attack cycle and accepted damage produces a brief hit reaction

### Requirement: Orders and progression compatibility
Hold SHALL keep its position, and Regroup SHALL cancel pending NPC contacts and projectiles before returning troops to camp. Changes SHALL preserve server authority, damage, health, reward values, troop counts, independent respawns and saved progress. Encounter state SHALL remain transient.

#### Scenario: Change orders during windup
- **WHEN** an owner selects Hold or Regroup before impact
- **THEN** the old pending strike is cancelled, Hold does not chase or retreat, and Regroup returns living troops to camp without resetting health or respawn deadlines

#### Scenario: Switch or lose authority
- **WHEN** an owner switches civilization, disconnects or loses writable progress during an encounter
- **THEN** stale pending actions cannot damage targets or generate kill rewards and their reservations are released

### Requirement: Shared troop spacing in travel and camp
Owned and neutral troops SHALL avoid sustained crowding with allied and enemy troop bodies during Advance, Regroup and camp rest. They SHALL walk, sidestep or yield without pushing or teleporting. Held actors SHALL remain stationary obstacles. Traffic waits SHALL NOT trigger stuck-recovery jumps. Camp destinations and paths SHALL respect other troops, yard bounds and the fire.

#### Scenario: Bridge traffic and camp arrivals
- **WHEN** opposing troops cross a bridge or four owned troops return to camp together
- **THEN** local passing and intentional yielding permit progress without sustained body overlap, water shortcuts or blocked camp entrances

### Requirement: Varied idle and recovery footwork
Troops SHALL use occasional small idle movements and varied recovery steps: ranged strafing and melee arcs or distance adjustments within reach. Footwork SHALL respect spacing, geometry and medical bounds, yielding to attacks, skills and orders without changing contacts or cooldowns. Windup, contact and Hold SHALL stay planted.

#### Scenario: Observe a duel and ranged firing
- **WHEN** unanchored combatants exchange attacks
- **THEN** recovery steps vary in timing and direction while actual damage and projectile release continue through the existing validated contacts

#### Scenario: Idle and Hold
- **WHEN** troops reach their rally or receive Hold
- **THEN** idle movements stay near the rally and Hold keeps root positions fixed
