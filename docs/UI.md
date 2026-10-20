# Interface panels

Use the minus button to minimize the settlement HUD, army commands,
civilization selector, Barracks recruitment or War Council. A labeled Open button
restores the panel. The HUD and army controls minimize independently; hiding
status never withdraws army commands. Information continues updating while hidden.

HUD and army restore buttons stay in their former panel area. Civilization
selection restores from the top center. Building-menu restore buttons sit below
the settlement HUD. Controls reflow for narrow portrait and landscape views.

Minimization is a local session preference. It survives respawns and ordinary
state updates, but is not written into saved civilization progress. It never
sends an earning, recruitment, army-order or formation-selection request.

Recruitment counts and scroll position stay intact when minimized. Closing a
building menu or interacting again starts the ordinary fresh menu flow. Leaving
its interaction range, dying, losing the building or changing civilization closes
the menu and removes its restore control, even while minimized. Server checks
still guard every actual Save or Select action.

Native buttons support mouse, touch and controller activation. Selected focus
moves to the restore button when its panel is hidden, and returns to an available
control when restored. Narrow-screen skill feedback appears in the skill button
so the separate message cannot cover restore controls or army commands.

Verification commands and measured runtime coverage are recorded in SETUP.md and
PLAYTEST.md. Bounded layouts and virtual input do not replace physical device tests.
