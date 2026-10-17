# Proposal

## Why

Armies currently top out at four troops and advance independently. The first Spartan formation should let the player prepare a protected five-troop group at camp, assemble on the settlement road and march together under explicit orders.

## What Changes

- All civilizations gain Army Camp II at settlement 18 (250 coins, Army Camp I and Barracks VI), adding an independent melee slot, and War Council I at 19 (200 coins, Training Yard I), with an accessible room and map table beside the training yard.
- Sparta gains Shield Training I at settlement/armor 15 (150 coins, Armorer I), reusing the player shield on player/melee rigs. Two validated frontal hits consume the shield for that life; rear/side hits bypass it. No stat bonuses or purchase/toggle refills.
- Sparta can purchase Spartan Shieldwall at settlement 20 (250 coins, shield training, War Council, five-slot capacity including hospital). The map table selects the formation; the HUD's separate March Formation command requires all five owned living troops in the training camp with three melee, one ranged and one medic.
- Troops first gather on the road outside the settlement, then march to the battlefield in a shallow convex shield arc (middle leading, outer two slightly behind) with ranged/medic side by side behind: `(:` when travelling left.
- Advance abandons formation and restores independent combat immediately. Hold stops movement but permits attacks/healing; Regroup cancels the march and returns to camp. Casualties, claim/life/authority changes stop stale formation control. Starting again requires a fresh camp muster.
- Persist unlocks and selection per civilization, with missing-only defaults and existing version-one keys. Live shields, march phases and troop health never save.

Confirmed: exclusive Spartan formation/shields; universal planning building/extra melee; physical unlock pad and map-room selection; camp readiness, road assembly, corrected arc, explicit Advance cancellation. Accepted tuning/defaults: levels/prices above, frontal block arc, respawn-only shield restoration, no formation stat multiplier, surviving troops Hold on casualty rather than waiting for replacements. Other formations, other faction shield assets, a level-20 settlement checkpoint, player formations/mounts and live publication are outside scope.

## Capabilities

### New Capabilities

- `formation-progression`: universal fifth slot/planning building, faction-gated paid unlocks and saved selection.
- `combat-shields`: shared player/troop two-hit frontal protection and immutable cosmetic lifecycle.
- `army-formations`: physical planning-table selection, validated camp muster, road assembly, coordinated marching and order/casualty cancellation.

### Modified Capabilities

None. Existing gameplay lives in other active changes; their current contracts remain compatible except the expanded Army Camp capacity and Spartan cosmetic shield becoming a purchased combat item, described here.

## Impact

Shared development/sites/pads/profile validation; Economy and ProfileService; equipment, CombatService and skill damage dispatch; army slot lifecycle/navigation/encounter integration; council geometry, guarded table remotes and responsive army/council UI. Add focused fake-store logic and native Studio fixtures for purchases, slot preservation, shields and actual five-body marching. No dependencies, source-asset mutations or storage-key changes.
