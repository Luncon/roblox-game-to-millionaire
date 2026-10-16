# Spec Delta

## Purpose

Make purchased farms visibly tended by the supplied farmer character with passive, repeatable crop-row walking routines.

## ADDED Requirements

### Requirement: Supplied farmer appearance
Farm tenders SHALL use inert copies of the supplied farmer rig, preserving its body, clothing and hat without modifying the source model or importing executable behavior.

#### Scenario: Farm is constructed
- **WHEN** a player purchases or restores a farm
- **THEN** its tenders display the supplied farmer appearance and the original rig remains unchanged

### Requirement: Crop-row routine
Each tender SHALL repeatedly walk through its assigned field's crop rows with visible limb movement, row-end changes of direction and short working pauses. Multiple tenders SHALL have staggered routines and remain within field bounds.

#### Scenario: Observe a full routine
- **WHEN** a farm remains active through one routine cycle
- **THEN** its tenders visit every crop row, pause to tend crops and return continuously to the beginning without teleporting

#### Scenario: Expanded farm
- **WHEN** Farm II and Worker Camp II are purchased
- **THEN** three tenders walk staggered routines adapted to the seven-row fields

### Requirement: Passive presentation and economy compatibility
Tenders SHALL remain nonblocking passive scenery without active Humanoid movement, damage, targets or kill rewards. A disabled Humanoid SHALL be used solely to render the supplied clothing. Farm yield, reserve capacity, worker counts, purchases and saved progress SHALL retain their existing behavior independently of routine progress.

#### Scenario: Walking and working
- **WHEN** tenders move or pause
- **THEN** farm production continues using the existing active-time rules and no combat actor or additional reward is created

### Requirement: Farm lifecycle
Routines SHALL follow their current plot position and rotation, preserve live tender instances during reserve updates and clean up with their farm on rebuild, civilization switch or claim release. Routine phase SHALL be transient.

#### Scenario: Reserve update on a moved plot
- **WHEN** an existing farm is moved and its reserve updates
- **THEN** the same tenders continue within the transformed fields without returning to their former world positions

#### Scenario: Owner releases a plot
- **WHEN** a claim is released
- **THEN** its farm and all tender presentation are removed without leaving running worker tasks
