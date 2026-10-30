# Mounted troop concepts

The user identified mounted troops as the next troop type and explicitly allowed
departures from exact historical correctness. The animal lineup below is now used
by the [mounted army implementation](Mounted%20Army%20Implementation.md). The visual
directions remain concept art guidance; only that implementation note describes
the delivered decoration and verified behavior.

## Fantasy lineup and art direction

Use recognisable real animals as enlarged fantasy war mounts. All remain ground
units; the proposed saddle, harness and armour treatments are original art ideas,
not claims about historical domestication or battlefield use.

| Civilization | Proposed mount | Visual direction |
| --- | --- | --- |
| Sparta | Lion | Bronze face guard, crimson harness cloth, muscular silhouette. |
| Britain | Warhorse | Redcoat cavalry rider, dark saddle leather and brass fittings. |
| Seneca | Elk | Broad antlers and practical woodland leather tack; preserve the existing faction outfit. |
| Mongol Empire | Steppe horse | Compact build, light leather protection and travel gear. |
| Vikings | Brown bear | Heavy leather harness, iron fittings and a broad silhouette. |
| Persia | Leopard | Spotted coat, purple cloth and bronze ornaments. |
| Sengoku Japan | Tiger | Striped coat with red-and-black lamellar-style protection. |
| Mauryan India | Asian elephant | Large silhouette, decorated cloth and a simple rider platform. |
| Spanish Empire | Bull | Strong horns, iron brow protection and crimson cloth. |
| Ancient Egypt | Oversized Nile crocodile | Low silhouette with gold-and-turquoise harness details. |
| Imperial Rome | Oversized wolf | Crimson saddle cloth and Roman-style metal protection. |
| Ottoman Empire | Dromedary camel | Tall one-hump profile, patterned green cloth and ornate tack. |
| Ming China | Rhinoceros | Heavy silhouette with red-and-gold protective plates. |

The horses retain two recognisable cavalry identities, with different body
proportions and tack. The other animals provide strong visual distinctions at
miniature scale. Oversized predators and crocodile riding are deliberate fantasy.
The Seneca elk is also a fantasy gameplay concept, not an assertion of a Seneca
mounted tradition. This permission concerns mount design; it does not revise
the existing architecture evidence cards.

## Historical anchors and limits

Research began with the existing faction windows in
[Civilizations](../../src/shared/Civilizations.luau). The user then approved a
less literal direction. These references support historical alternatives or
anchors, not the fantasy roster as a whole:

- [National Army Museum: cavalry roles](https://www.nam.ac.uk/explore/cavalry-roles)
  supports British horse cavalry, including late-eighteenth-century dragoons.
- [Royal Armouries: Mongol arms and armour](https://royalarmouries.org/objects-and-stories/stories/the-mongols/arms-and-armour-of-the-mongol-empire)
  supports mounted Mongol warriors and horse equipment.
- [Plutarch, Life of Alexander](https://penelope.uchicago.edu/Thayer/E/Roman/Texts/Plutarch/Lives/Alexander%2A/9.html)
  records Chandragupta's elephant transfer to Seleucus; it supports the Mauryan
  elephant connection, not the proposed platform's exact design.
- [The Met: horses harnessed to a chariot](https://www.metmuseum.org/art/collection/search/544062)
  documents an earlier New Kingdom horse/chariot reference. A horse-drawn chariot
  remains the more literal Egyptian alternative to the proposed fantasy crocodile.

The supplied animals, riding poses and distinct facilities are implemented in the
isolated miniature sandbox. Facilities cost 5,000 Coins and provide one rider at
two army slots. See the implementation note for the current combat budget,
verification and remaining boundaries.
