# Army Control

Army Control adapts the building selection and deployment flow in
[Mini Wars References](Mini%20Wars%20References.md). Army 1 always includes every
placed military building, including structures waiting for army capacity. Research
unlocks Army 2; the following two army-slot upgrades unlock Armies 3 and 4.

Press hotbar **3** after unlocking Army Control. Select **Edit** on a custom army,
then click your military buildings to include or remove their whole troop groups.
Selected buildings receive a gold outline. **Save group** commits the selection;
Cancel keeps the previous saved membership. A building can belong to one custom
army. Remove it from that army before assigning it to another. Army 1 remains all
troops. Presets are saved separately for each player and civilization.

At an outpost, press **E**, choose an army and press **Deploy**. Before researching
Army Control, E retains the existing whole-army order. Deploying a custom army
changes only its buildings' targets; new replacements from those buildings inherit
the same order. Deploying Army 1 clears custom overrides and directs everyone.
Targets are temporary and clear on civilization changes or lost authority.
Commander death does not cancel surviving troops' orders; request epochs still
invalidate stale UI actions from that commander life.

Editing or resetting membership does not redirect living troops, refill health,
alter respawn clocks or charge Coins. Reclaiming a military structure removes its
saved membership and temporary order. A newly placed structure has a new identity
and must be added to a custom group again.

Minimizing the panel preserves its draft. Life, claim, write authority and outpost
distance continue to be checked while panels are hidden. Deploying rechecks the
living owner's proximity on the server; an open chooser does not retain permission
after walking away.

Implementation: shared `ArmyGroups` validates fixed dense `army2`/`army3`/`army4`
arrays, disjoint owned military IDs and research slots. `CombatController` owns
transient building targets, including waiting-capacity structures, and supplies
them to the authoritative battle. Clients request a group number and outpost;
the server derives actual membership. Session, claim epoch, revision, replay and
profile-write guards remain in the existing request path.

Eight deterministic group cases cover validation, atomic refusals, disjoint
membership, reclamation, state isolation and preservation of troop/economy/order
data. The integrated miniature suite passed 177 cases plus the immutable animal
asset audit when this slice was checked.

The October 29 isolated native run passed `MilitaryFlow`, `MilitaryLayouts` and
`ArmyControlFlow`: actual research clicks waited for the Army Control unlock;
hotbar 3 opened the panel; owned building clicks and Save configured Army 2;
the commander walked 256 studs and used E to deploy that group at another
outpost. Its building troops changed target while the other group retained its
target. Responsive bounds passed separately. The legacy pre-unlock command is
retained; this native group fixture exercises the researched chooser. This is
Studio fake-store/client evidence, not public-server,
real-storage or multiplayer certification.

The fresh ordinary200-Coin baseline subsequently verified pre-unlock E through
actual walking/input: one Army1request, no deploy chooser, and the manual target
accepted. It also passed paid placement, hammer return and replacement. See
[complete evidence and review builds](Military%20Research%20and%20Army%20Control.md).
