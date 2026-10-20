# Spec Delta

## Purpose

Let players temporarily hide interface panels while retaining their current contents and a reachable way to restore them during gameplay.

## ADDED Requirements

### Requirement: Independent panel minimization
The settlement HUD, army controls, civilization selector, Barracks and War Council SHALL each expose a minimize control and labeled restore control. Minimizing SHALL hide the panel and any blocking overlay without altering game progress, commands or pending selections.

#### Scenario: Minimize and restore a panel
- **WHEN** the player minimizes an available panel
- **THEN** its contents and overlay are hidden and its restore control is visible
- **AND** restoring shows the current contents without issuing a game action

#### Scenario: Keep army and HUD independent
- **WHEN** the settlement HUD is minimized while army controls are unlocked
- **THEN** army controls remain available and can be minimized or restored separately
- **AND** state updates and viewport changes do not reopen minimized panels

### Requirement: Context and draft preservation
Minimized building menus SHALL preserve their local draft and continue their existing life, proximity, building and civilization checks. Closing an invalid menu SHALL remove its restore control. Minimization SHALL remain local to the client session and SHALL NOT save profile fields or bypass server action guards.

#### Scenario: Preserve recruitment draft
- **WHEN** the player edits recruitment counts, minimizes and restores while still eligible
- **THEN** the unsaved counts remain and no composition request is sent

#### Scenario: Leave a minimized building menu
- **WHEN** the player leaves interaction range, dies, loses the building or changes civilization
- **THEN** the menu and its restore control close
- **AND** a later legitimate interaction can open a fresh menu

### Requirement: Reachable controls and focus
Minimize and restore controls SHALL use native button activation, visible labels and reachable bounds in supported portrait and landscape layouts. Hidden panels SHALL NOT retain selected input focus. Restoring SHALL restore an available focus target without changing gameplay eligibility.

#### Scenario: Restore with controller selection
- **WHEN** a selected panel is minimized and its restore control is activated
- **THEN** focus moves to the restore control while hidden and returns to a visible selectable control on restore

#### Scenario: Resize with a minimized panel
- **WHEN** the viewport changes between narrow portrait and landscape layouts
- **THEN** restore controls remain inside the viewport and do not cover other panel command or minimize controls
