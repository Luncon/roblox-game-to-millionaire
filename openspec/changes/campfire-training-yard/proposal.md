# Proposal

## Why

The training yard currently contains practice posts inside the settlement, while Regroup sends troops to fixed positions near the barracks. A campfire yard beside the plot will give returning troops a recognizable gathering place and make a resting army feel alive.

## What Changes

- Confirmed: replace the training yard's practice-post appearance with an original campfire gathering area inspired by the army-camp feel of Clash of Clans.
- Confirmed: place the yard off to the side of the settlement and its construction pad outside the main plot, beside the future yard.
- Confirmed clarification: regrouped troops gather at the campfire yard and wander slowly within that yard, rather than walking around the entire plot.
- Proposed defaults: preserve the level-5 unlock, 50-coin purchase, training progression and saved trainingLevel. Use a fixed side site outside the final level-50 foundation so expansion never covers the yard or its pad.
- Reserve flat terrain, a clear approach and a side opening in later settlement walls. Move the purchase pad with the site and retain existing purchase validation.
- Regroup continues to cancel attacks and in-flight shots. Each troop reaches the camp first, then alternates slow walking and brief pauses inside the yard. Advance resumes normal movement; Hold stops the current wander.
- Outside scope: new troop slots, training bonuses, healing, formations, new purchases, saved orders or imported game assets.

## Capabilities

### New Capabilities

- `training-camp`: Exterior campfire yard, adjacent purchase site, protected regroup arrival and bounded idle movement.

### Modified Capabilities

None. The main spec inventory currently contains only development-workflow. This capability specializes the server-chosen regroup rally described in the active settlement-development-milestone change without altering command eligibility or progression.

## Impact

- Shared SettlementSites and PadCatalog; SettlementInfrastructure visuals; BattlefieldMap camp rally helpers; Topography/scenery reservations; SettlementDistricts approach clearance and perimeter opening.
- WarriorService regroup state, walking speed and transient idle goals; reuse WarriorNavigator and shared combat protection.
- World and army command fixtures, native movement tests, and docs/ARMY.md, docs/WORLD.md and docs/PLAYTEST.md.
- No new dependencies, remote destinations, profile fields, data migrations or source-asset changes. Existing uncommitted neutral-opponent work remains intact.
