# Proposal

## Why

Vikings need a formation with an offensive purpose distinct from the existing marching guards and Persian firing screen. The approved Shield Wedge concentrates three shieldmen before releasing them into ordinary combat on melee contact.

## What Changes

- Unlock Viking Shield Training and Viking Shield Wedge through the existing armory and War Council progression, at unchanged prices and prerequisites.
- Require three melee shieldmen, one axe thrower and one medic gathered in the Training Yard. Assemble on the road, then march a pointed wedge at six studs per second with paired support behind.
- Release to ordinary Advance when a captured frontline member has a valid melee contact, a frontline casualty occurs, or the formation reaches its final destination. Explicit Hold stays stationary and permits attacks and healing; Advance and Regroup cancel formation control.
- Reuse two-hit frontal shields and rack collection without extra damage, speed or protection bonuses. Preserve living troops, pending respawns and civilization-isolated formation selection.

Confirmed: the user requested the previously proposed Viking formation, including the five-troop wedge, shared speed and melee-contact release. Implementation defaults: existing level-15 shields and level-20 formation progression, shared shield art, ordinary axe skills after release, and forward-facing shields. New historical assets, other civilizations, charge bonuses and publishing are outside scope.

## Capabilities

### New Capabilities

- `viking-formation`: Viking wedge progression, geometry and server-validated release into combat.

### Modified Capabilities

None in the main inventory. Existing formation change contracts remain the compatibility baseline.

## Impact

Shared formation definition, authoritative formation coordinator/contact policy, existing profile/economy/UI integration, deterministic regression tests and isolated Studio scenarios. No new save fields, dependencies, remotes or source asset mutations.
