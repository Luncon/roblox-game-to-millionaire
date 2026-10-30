# Proposal

## Why

The user supplied animal models and requested mounted troops as the next army
class. Existing assets include independent gameplay scripts and inconsistent
rigs/scales; they need an isolated, coherent adaptation to the miniature army.

## What Changes

- Use the supplied animals with civilisation-specific riders, decoration,
  practical scales and ground-based locomotion/combat animations.
- Provide thirteen named, visually distinct animal facilities through the normal
  Military shop. Each costs 5,000 Coins and supplies one automatic mounted troop.
- Count each mounted troop as two army slots under the existing ten-slot cap.
- Preserve current combat authority, capture/order rules, inventory/reclaim flow
  and unrelated troop lives, health and replacement deadlines.
- Archive raw imports without executing them; map only sanitised visual templates.

Confirmed: supplied models, creative freedom, individual structure themes,
5,000-Coin price and two slots per mount. Design choices: one rider per building,
shared mounted combat budget and a tiger-derived leopard for Persia, since the
supplied set contains eleven animal templates.

## Capabilities

### New Capabilities

- `miniature-mounted-armies`: purchases, weighted capacity, mounted lifecycle,
  safe imported visuals, riders, locomotion and faction-specific facilities.

### Modified Capabilities

None. Existing miniature gameplay changes remain unarchived. The old production
mounted-power proposal is not this feature and is not being implemented here.

## Impact

Miniature server/client/shared code, isolated mount templates, generated test
projects, regressions and the Obsidian vault. No player riding controls, flights,
research, new production services, live storage, or production/preview changes.
