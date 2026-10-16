# Tasks

## 1. Encounter decisions and spacing

- [x] 1.1 Implement shared frozen tuning and pure stable targeting, threat scoring, melee reservations/separation and ranged geometry; verify focused tests for crowd overflow, coincident positions, target hysteresis, protection and retreat bounds.
- [x] 1.2 Implement shared encounter state and integrate both NPC services with guarded close navigation; verify unanchored approach, stationary Hold, shared reservations and release/teardown behavior, and document movement rules in docs/ARMY.md.

## 2. Timed attacks and presentation

- [x] 2.1 Implement frame-level locked-target windup/contact/recovery and server-authorized contacts; verify exactly-once damage/release, range/LOS/arena/lease interruption, cooldown preservation and Regroup cancellation with focused tests.
- [x] 2.2 Implement weapon-family R6 poses and brief accepted-hit feedback; verify immutable source/rest geometry and visually inspect generated/imported spear, blade/axe and ranged motion, and document attack rules in docs/ARMY.md.

## 3. Native integration and independent review

- [x] 3.1 Add the repeatable fake-store --solo --combat runner and execute full module regressions plus six unanchored NPC encounters; record spacing, attack timing, ranged movement, command results and rendered captures in docs/PLAYTEST.md.
- [x] 3.2 Complete an independent reviewer pass, address findings and perform focused two-real-client pose/authority verification where available; document concrete results or any unavailable runtime limitation.
- [x] 3.3 Run strict OpenSpec validation, production/test Rojo builds and final diff/source checks; restore normal Studio startup, verify original templates and remove owned test fixtures.
