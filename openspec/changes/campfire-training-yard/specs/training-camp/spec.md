# Spec Delta

## Purpose

Give each civilization an exterior campfire training yard where its army can regroup and rest with slow, bounded movement.

## ADDED Requirements

### Requirement: Exterior campfire yard
Buying the existing training upgrade SHALL create a recognizable campfire gathering yard off the side of the settlement. It SHALL include a stone fire ring, logs, a visible flame and open standing space. The fire SHALL be decorative and deal no damage. The yard SHALL remain outside the final settlement foundation and clear of the battlefield, farms, neighboring plots and main troop road.

#### Scenario: Purchase the campfire yard
- **WHEN** an eligible owner buys the training upgrade
- **THEN** a campfire gathering yard appears beside their plot instead of the previous practice posts
- **AND** characters and troops can safely stand and move around the fire

### Requirement: Exterior construction pad
The training construction pad SHALL appear outside the main settlement plot beside the future yard, starting at settlement level 5 and priced at 50 coins. It SHALL remain usable while unaffordable and disappear after purchase. The pad and its standing space SHALL remain outside the foundation through level 50. Existing owner, proximity, purchase and writable-profile checks SHALL apply.

#### Scenario: Unbuilt side site is discoverable
- **WHEN** an owner reaches settlement 5 without buying training
- **THEN** the exterior training pad marks the future campfire yard and shows its 50-coin price
- **AND** the old interior training purchase site is absent

#### Scenario: Existing trained civilization returns
- **WHEN** a saved civilization with purchased training is selected
- **THEN** its campfire yard is restored without another purchase and its completed training pad is absent

### Requirement: Clear and grounded access
Each yard, construction pad and approach SHALL use reserved grounded space. Owners and troops SHALL be able to walk between the settlement and yard at every supported growth stage, including through later perimeter walls. These reservations SHALL follow moved or rotated plots, preserve developer geometry and retain the landscape's 2,000-static-part limit.

#### Scenario: Fully expanded settlement remains connected
- **WHEN** a trained settlement grows through levels 20 and 50
- **THEN** its yard, exterior pad site and approach remain unobstructed by walls, new districts or scenery

### Requirement: Regroup arrives at the training yard
Regroup SHALL cancel pursuit, attacking and the army's in-flight shots, then send each living owned troop to a server-chosen arrival position around its own campfire. Troops SHALL walk there using normal return speed and remain non-attacking throughout the order. Replacement troops SHALL first return to the yard when Regroup is active. Client-provided destinations SHALL NOT control movement.

#### Scenario: Army walks home to the fire
- **WHEN** an eligible owner issues Regroup while their melee, ranged and optional reinforcement troops are active
- **THEN** each troop walks to that owner's campfire yard without attacking or pursuing enemies
- **AND** no troop uses the former barracks rally as its final resting destination

### Requirement: Slow wandering stays within the yard
After arriving, regrouped troops SHALL alternate slow walking and short idle pauses within the training yard. Their movement SHALL be slower than normal battlefield movement, remain clear of the fire, stay outside the arena and preserve troop health, class and identity. A troop that cannot reach a wander goal SHALL retry or choose another safe goal without teleporting or leaving the yard.

#### Scenario: Resting troops stroll around the campfire
- **WHEN** a regrouped troop reaches its yard and is observed through multiple idle cycles
- **THEN** it changes position slowly between safe points around the fire and pauses between walks
- **AND** it remains inside its owner's yard without attacking or taking fire damage

### Requirement: Orders interrupt resting movement
Hold SHALL immediately stop future wandering and retain each troop's current position under existing hold combat rules. Advance SHALL cancel resting goals and restore normal movement speed and autonomous fighting. Repeating Regroup SHALL NOT repeatedly reset an ongoing walk or pause. Gear and settlement upgrades SHALL preserve the active order, living identities, health deficits and pending respawn deadlines.

#### Scenario: Advance leaves camp at normal speed
- **WHEN** an owner issues Advance while troops stroll around the campfire
- **THEN** the troops stop following resting goals and resume battlefield movement at their normal speed

#### Scenario: Hold interrupts a stroll
- **WHEN** an owner issues Hold during a troop's resting walk
- **THEN** it stops wandering at its current position until a later eligible order

### Requirement: Existing progression and transient lifecycle
The campfire yard SHALL use the existing training purchase and saved training progression. It SHALL preserve level-10 prerequisites, owner command eligibility, army capacity and respawn rules. Resting goals, phases and pauses SHALL be transient and cleared when troops or their civilization are released. Switching or rejoining SHALL retain the current reset-to-Advance behavior.

#### Scenario: Upgrade during a respawn wait
- **WHEN** an owner upgrades gear or settlement while Regroup is active and a troop awaits replacement
- **THEN** the pending deadline is preserved and its eventual replacement walks to the camp before wandering
