# Military research and army control

October29,2026. Implemented from the expanded
[Mini Wars reference](Mini%20Wars%20References.md), including its research table,
hex tree, army edit/deploy screenshots and inventory instructions.

The miniature version is now the default Clash of Civilizations development
build: `default.project.json`, port34872. The previous mapping is preserved as
`legacy-fullscale.project.json`; the clean scale preview and dated backups remain.
Main startup still uses Studio-only injected FakeProfileStore. No public release
or real profile migration is included.

The current change implements29military nodes, retaining listed prices/times as
initial tuning. Modern vehicle bonuses become mounted troop bonuses with themed
names. Modern-unit/missile unlocks and the civilian half remain grey placeholders.
Building purchases remain available without research. One project per civilization
advances during living, writable active play; switching, death and offline time
pause it. Tiers add together, with no heal or respawn reset on completion.

Army1 always includes every military structure. Army Control unlocks one editable
army and each following control tier adds another, up to Army4. Custom groups use
disjoint owned building selections. Deploy at an outpost through E; before this
research, E retains the existing whole-army order. Group presets save per
civilization; outpost targets are transient.

Inventory is slot1/B, Destroy Hammer slot2, and researched Army Control slot3.
Buildings and goods appear as grid images with stack counts. Slots4–9 provide
quick access to held buildings.

## Verification

The strict development gate passes34OpenSpec items,9Node cases,399Luau syntax
files,244original logic cases and177miniature logic cases at this checkpoint.
The unchanged animal-bank check passes11inert templates/523parts plus the retained
raw backup. Eight focused army-group cases cover dense, disjoint membership,
locked groups, atomic refusals, reclamation and independent presets.

Native Studio verification used a separate Coin-only research fixture with
100,000Coins per civilization and no completed research or injected troops. Its
isolation boundary passed. Actual input selected Sparta, panned/zoomed the
29-node/28-edge hex tree with17inert placeholders, then purchased Army Training,
Officer Training and Army Control. Real elapsed times were30.21,60.28and60.21seconds.
All completed while minimized, with server countdowns and completed hex updates.
Coins moved100,000→99,000→74,000→69,000; no completion request or second charge.
Slot1 inventory click/B parity, key2 hammer toggles and researched key3 army opening
passed. Physical number1 and physical phone/controller input remain separate checks.

Native render bounds passed320×360,320×568,640×360and1024×768. The shortest graph
retains72pixels; inventory content retains116pixels for104-pixel image/count tiles.
These checks use isolated presentation copies and send no gameplay requests.
Native building-group edit/deploy verification passed. Actual purchases paid500Coins
for melee/ranged items. An initial fixture placement click hit its Cancel overlay;
the fixture was corrected to visible legal sites and reused those paid items.
Actual placements at(16,−22)/(28,−22) spawned four troops. Edit Army2, minimize,
world-select the melee structure, restore, Save, Reset and reconfigure all passed;
Army1 retained both buildings while Army2 contained only melee. Actor identities,
lives and health survived edits. The commander walked256studs through native W input
to outpost2 and pressed E to deploy Army2. Assigned actors targeted outpost2 while
unassigned ranged actors retained outpost1, and Army1 reported mixed targets.
No local relocation or authoritative state injection was used.

A passive native observer also measured34.5melee and27.6ranged damage on living
neutral defenders after Army Training and Officer Training (+15%foot damage),
confirming that research affects real ongoing combat rather than only UI values.

The fresh ordinary default build passed its separate200-Coin acceptance flow:
walk to farm/E collects60actual goods, Sell All yields320Coins, the250-Coin melee
building leaves70. Slot1 opens the real grid with×1; placement spawns two troops.
Key2 plus E returns the building item, removes source/local troop visuals without
creating combat corpses, preserves70Coins and restores×1. Replacing consumes that
same item with no extra fee and restores two troops. Native W travel to the home
lane's outpost followed by E sent exactly one all-army request before Army Control,
opened no deploy chooser and set its manual target. No state or position injection.

The final four-size native render repeat also verifies that the hotbar hides while
the Research panel is open, avoiding overlap with its short-screen action button.
The normal build contains no legacy bootstrap or native test runners and starts
with empty military research, one all-army group and capacity10. Its full-size
legacy project mapping is byte-identical to the previous default mapping.

Review found no introduced authority or save-migration defects. Existing imported
asset approval/type warnings remain visible in Studio. A pre-existing reconnect
during a delayed profile-close retry is a separate lifecycle follow-up. Published
multiplayer/storage, physical phone/controller input and the all-civilization
native research/combat matrix remain separate checks.

## Review builds

The follow-up [thorough regression pass](Military%20Research%20Thorough%20Test%20Pass.md)
adds48logic cases and broader native all-civilization, UI, lifecycle, network
and ragdoll checks. Current results:225miniature and244original logic cases pass.

- `build/clash-of-civilizations-main.rbxlx`: ordinary200Coins; default project.
- `build/clash-of-civilizations-funded-review.rbxlx`:20,000testCoins for all13civilizations; no diagnostic autorunners.
- `build/clash-of-civilizations-military-research-test.rbxlx`: explicit100,000Coin research fixture; no completed-project injection.

Rebuilt places already contain their scripts. Open the desired file and press
Play; no Rojo Sync is needed. The user's existing playtest was preserved; owned
verification Play sessions were stopped after evidence collection. All miniature
progress remains temporary and resets when its Play server stops.

Detailed rules: [military projects and modifiers](Military%20Research%20Rules.md).
Requirements and task progress: [main military change](../../openspec/changes/miniature-main-military-research/proposal.md).
