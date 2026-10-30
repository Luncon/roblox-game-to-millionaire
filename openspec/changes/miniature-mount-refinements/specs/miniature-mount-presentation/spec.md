# Spec Delta

## Purpose

Keeps supplied miniature mounts recognisable, coherently seated and animated, with species-specific movement that matches playtest feedback.

## ADDED Requirements

### Requirement: Species movement speeds

Elephants and camels SHALL move at 5.5 studs per second, slightly below regular troops at 6. Other mounts SHALL retain 9. Species speed SHALL be shared by server combat and movement without changing health, damage, army capacity or existing respawn deadlines.

#### Scenario: Slow species march with regular troops

- **WHEN** elephant and camel troops march under normal orders
- **THEN** their authoritative movement uses 5.5 studs per second while regular troops retain 6 and other mounts retain 9
- **AND** synchronization does not reset their living identities, health or pending replacements

### Requirement: Requested mount proportions and seating

Elk SHALL be visibly smaller and bears only slightly smaller than their prior versions. Lion riders SHALL sit on the visible back without a floating gap. Bulls SHALL have short, thick, block-shaped feet. Original rider outfits and immutable imported templates SHALL be preserved.

#### Scenario: Reviewing adjusted mounts

- **WHEN** the elk, bear, lion and bull are displayed or animated
- **THEN** their proportions and seating reflect the requested corrections
- **AND** riders, gear and supports remain connected and grounded on normal and raised surfaces

### Requirement: Animal facial details and gait

Wolves SHALL have visible black eyes. Rhinoceroses SHALL have eyes and a more pronounced snout while retaining the existing Roblox art style. Crocodile feet SHALL visibly sway during locomotion and stop their walking cycle when stationary.

#### Scenario: Crocodile walking and resting

- **WHEN** a crocodile changes between walking and standing
- **THEN** its splayed feet visibly sweep while walking and settle while stationary
- **AND** its rider and animal stay within the same grounded joint hierarchy
