# Tasks

Phase-one checklist only. Phase-two mounts remain specified but deferred; completing this checklist does not complete the combined change or authorize archival of its pending mount requirements.

## 1. Shared skill catalog and saves

- [x] 1.1 Add family aliases, five-tier prices/requirements and approved cooldown/damage tables; verify all thirteen melee variants plus ranged axe/javelin variants map correctly and unsupported/neutral actors remain excluded.
- [x] 1.2 Extend ProfileData, Economy and every snapshot/publication/copy path with skillLevel; verify fake-store missing-only defaults, fifteen-field round trips, invalid tiers/prerequisites, independent civilization restoration and unchanged original fourteen fields. Document migration/rollback in docs/PROFILES.md.

## 2. Training camp purchase slice

- [x] 2.1 Add sequential skill offers and exact server charges without workshop discounts; verify prerequisite, funds, foreign-owner, lease and duplicate-event cases using injected state fixtures. Document level thresholds and 2,000-coin total in docs/ECONOMY.md.
- [ ] 2.2 Place the next eligible skill pad beside the training camp with labels, affordability and absent locked/completed pads; verify native Studio purchase, one-purchase-per-entry behavior and clearance from the fire/rest routes.
- [x] 2.3 Apply purchased tiers to existing and replacement eligible units; verify no healing, troop replacement, slot change, cooldown reset or respawn deadline change and observe save/restore in the isolated harness.

## 3. Shared action and damage authority

- [ ] 3.1 Coordinate ordinary attacks, skill action locks and actor/slot cooldown deadlines; verify rejected spam, death/switch/replacement preservation, accepted misses spending cooldown and no overlapping projectile/ordinary/skill action in engine fixtures.
- [x] 3.2 Add restricted validated skill contacts through the shared damage/reward path; verify per-life deduplication, source authority, visibility, protected boundaries, fractional role damage and no recursive contact effects. Run existing combat fixtures to establish unchanged ordinary attacks.

## 4. Three independently playable skills

- [ ] 4.1 Implement spear Dash Thrust and coordinated poses; verify 8-second cooldown, every tier multiplier, first-hostile contact, ten-stud cap, grounding, walls/slopes/boundaries, Hold prohibition and safe cancellation in isolated engine tests and a solo Studio run.
- [x] 4.2 Implement axe Whirlwind and spin animation; verify 12-second cooldown, per-tier damage, six-stud radius, nearest-three cap, per-life single contact and wall/friendly protection in engine fixtures and solo Studio.
- [x] 4.3 Implement sword Double Slash and linked poses; verify 9-second cooldown, two contact multipliers, 0.35-second separation, one target life, second-hit escape/death/visibility checks and recovery action exclusion in engine fixtures and solo Studio.
- [ ] 4.4 Integrate eligible ranged javelin/axe NPC close-range skill decisions; verify normal projectile cadence at distance, no concurrent shot/skill, role damage multiplier and cancellation on Regroup in isolated engine tests. Document all three skill formulas and tactical rules in docs/ARMY.md.

## 5. Player controls and roster presentation

- [ ] 5.1 Add skill action/readiness feedback for keyboard, touch and gamepad; verify purchased/locked/cooldown feedback and correct family behavior in Studio with documented bindings.
- [ ] 5.2 Verify player R15 and all NPC families/custom skins animate without changing original joints, grips, hats or clothing; add immutable-template fixtures and capture representative dash/spin/combo gameplay evidence.

## 6. Phase-one integration evidence

- [x] 6.1 Run npm run check, a Rojo build and isolated solo fake-store regression suite; record results and any inaccessible runtime checks in docs/PLAYTEST.md without claiming build/validation proves gameplay.
- [ ] 6.2 Run one focused two-player Studio session for skill replication, dash collision, combo escape, multi-target rewards and civilization isolation; measure skill damage/time-to-kill at tiers I and V and close owned windows before the next run.
- [ ] 6.3 Check actual keyboard/touch/gamepad inputs in available Studio or published clients and separately verify real StudioDevelopment tier restoration; document exact coverage and keep regression fixtures isolated from player stores.

## Workflow follow-up

- After phase-one acceptance, revisit the retained civilization-mounts contract and create its implementation checklist before starting phase two. Preserve combat and transport animals, including Mauryan elephants and Egyptian camels.
- Civilization-specific specials, customizable elemental effects and ultimates require later planning; they are not phase-one tasks.
- Do not archive the combined change while mounts remain pending. If independent phase-one archival is desired, first approve a separate mount change and reconcile capability ownership.

## Implementation evidence

Phase-one source, pads, player R/gamepad Y/touch controls, troop integration and
isolated fixtures are present on `feature/troop-weapon-skills`. Standalone logic
passes 81 cases. Studio MCP now works: all 307 module cases and a native solo
combat/purchase run passed using fake persistence. See docs/PLAYTEST.md and its
JSON evidence for exact coverage. Unchecked tasks retain remaining acceptance
checks; native R success does not establish touch/gamepad input or multiplayer
replication. Real storage and published clients remain unverified. Mount work
remains deferred. Keyboard R is the user's confirmed player binding.
