# Spec Delta

## Purpose

Let Seneca commanders deploy a shieldless ranged squad that concentrates fire while retaining bounded local defense and evasion.

## ADDED Requirements

### Requirement: Shieldless formation progression
Seneca SHALL unlock Focused Volley for 250 coins at settlement 20 after War Council I, Barracks Capacity II and Hospital I. Shield Training SHALL NOT be offered, required or granted for Seneca or Japan. Selection SHALL preserve existing owner, proximity, life, civilization and writable-profile checks and civilization-isolated save keys.

#### Scenario: Unlock without shields
- **WHEN** an eligible Seneca owner purchases Focused Volley and selects it at their council
- **THEN** the server deducts 250 coins and saves the selection without any shield or armor requirement
- **AND** neither a shield purchase pad nor shield rack is created for Seneca

#### Scenario: Preserve other factions and old profiles
- **WHEN** old profiles load or shield factions purchase formations
- **THEN** existing save defaults, shield prerequisites, charges and prices remain unchanged
- **AND** foreign selection, invalid shield state and lost write authority remain rejected

### Requirement: Ranged composition and crescent deployment
Focused Volley SHALL require one living melee guard, three living archers and one living medic in the owned Training Yard. Captured lives SHALL assemble on the road and march at six studs per second in a loose crescent with guard forward and medic behind, deploying at a clear 40-stud archer opportunity or final destination.

#### Scenario: Muster the selected composition
- **WHEN** the owner recruits 1 melee, 3 ranged and 1 medic and gathers those current lives in camp
- **THEN** March Formation assembles the squad in the faction layout
- **AND** incomplete, wrong-class, dead or outside-camp squads are rejected with accurate composition feedback

#### Scenario: Deploy at ranged opportunity
- **WHEN** any captured archer has a clear valid hostile within 40 studs
- **THEN** the group deploys without waiting for an attacking or displaced support to restore marching cohesion
- **AND** the deployment stays latched when the target leaves

### Requirement: Coordinated ordinary ranged attacks
Deployed archers SHALL prioritize a shared current hostile that at least one captured archer can legally shoot, retaining the target until invalid. Each archer SHALL independently validate visibility, normal range, authority and target life, using ordinary fallback selection when the focus is not shootable. Archer attack starts SHALL be at least 0.45 seconds apart without bypassing individual cooldowns or pending contacts.

#### Scenario: Focus and stagger
- **WHEN** multiple captured archers can shoot the focus
- **THEN** their validated ordinary arrows concentrate on it with staggered attack starts
- **AND** no ranged weapon skills, damage bonuses, extended range or extra shots are granted

#### Scenario: Retarget safely
- **WHEN** the focus dies, is replaced, becomes friendly, protected or invisible to every captured archer
- **THEN** the server chooses another valid current target or clears the focus
- **AND** blocked individual archers do not shoot through cover or allied troops

### Requirement: Bounded defense and command continuity
The guard SHALL intercept within 14 studs of its slot and return afterward. Archers SHALL use safe local movement within eight studs of their slots, including lateral repositioning and short retreats. Hold SHALL suppress movement while allowing attacks and medic healing. Advance and Regroup SHALL cancel coordination. Guard loss or loss of all archers SHALL release ordinary Advance unless explicitly held; replacements SHALL NOT join a captured group.

#### Scenario: Evade without endless retreat
- **WHEN** an enemy approaches a deployed archer
- **THEN** the archer can make a safe bounded reposition while the guard engages nearby threats
- **AND** neither can pursue indefinitely outside the formation boundary

#### Scenario: Commands and casualties
- **WHEN** the commander holds, advances or regroups, or a captured life dies
- **THEN** movement, pending-shot cancellation, medic healing and surviving captured membership follow the specified order and casualty rules
- **AND** health, existing cooldowns, recruitment selections and independent respawn deadlines are preserved
