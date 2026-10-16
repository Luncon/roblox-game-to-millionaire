# Spec Delta

## Purpose

Keep civilization settlements visually supported and free of unintended building intersections throughout growth and purchased infrastructure restoration.

## ADDED Requirements

### Requirement: Architecture is supported by its actual ground

Settlement architecture SHALL connect to its foundation or exterior ground through physical supports. Pillars, wall bases, roofs, gate beams, physical signs, upgrade pads and fence rails MUST have supporting geometry; surface skins and flush decorative attachments SHALL retain only small assembly clearances.

#### Scenario: Sparta level twelve
- **WHEN** a player views Sparta at settlement level twelve
- **THEN** its processional pillars and dwelling podiums visibly connect to the foundation without the existing one-stud air gap

#### Scenario: Purchased and rural structures
- **WHEN** eligible buildings and both farm tiers are restored for any civilization
- **THEN** their bases, signboards and fence rails have physical supports on the correct foundation or exterior ground, while crop rows meet their soil

### Requirement: Roofs meet their building geometry

Roofs SHALL cover their supporting walls without walls protruding through the roof exterior. Pitched roofs SHALL scale their elevation with building width and include connected attic or gable geometry. Flat roofs, vents, capitals and rooftop features SHALL remain connected to the structure they decorate.

#### Scenario: Wide ceremonial halls
- **WHEN** a wide hall is constructed for a civilization using pitched roofs
- **THEN** its upper walls remain below the roof exterior and the roof connects to the walls through supported construction

#### Scenario: Starter and flat-roof themes
- **WHEN** a starter tower or a district with flat roofs is built
- **THEN** its first tier and roof sections have no unsupported gaps, and posts do not visibly penetrate beneath the foundation surface

### Requirement: Separate structures retain clearance throughout growth

Separate buildings, ceremonial gates and perimeter walls SHALL avoid unintended physical penetration at every unlock level. Intentional shared joints, facade attachments and foundation surface layers SHALL be distinguished from collisions between independent structures.

#### Scenario: Grand longhouse unlock
- **WHEN** a longhouse civilization reaches level thirty
- **THEN** its grand hall, end posts and footing clear both the ceremonial gate and the current perimeter wall

#### Scenario: Growth and restoration matrix
- **WHEN** any of thirteen civilizations is built at any of fifty levels, including translated and rotated plots and eligible infrastructure
- **THEN** independent structures retain clearance within their growing footprint and the existing 400-part settlement budget

### Requirement: Upgrade pads have grounded supports

Every visible earning, purchase and collection pad SHALL connect to its foundation or exterior ground through physical support without changing its configured location, eligibility, price or interaction behavior.

#### Scenario: Pads inside and outside the settlement
- **WHEN** pads appear or are restored at any eligible settlement level
- **THEN** their undersides meet a support connected to the actual foundation or exterior ground, including the training-yard and farm sites

### Requirement: Geometry repairs preserve progression and access

Geometry repairs SHALL preserve the existing fifty-level unlocks, successive growth identities, pad locations and access, barracks spawns, arena exit, training-yard route and transient farmer routines. They MUST NOT change economy, saves, combat authority, source assets or unrelated developer geometry.

#### Scenario: Existing settlement is restored
- **WHEN** a saved settlement is rebuilt with corrected geometry
- **THEN** its existing purchases, progression and accessible controls are retained without new charges or changes to saved fields

#### Scenario: Verification is isolated
- **WHEN** automated geometry and native-access checks run in Studio
- **THEN** they use isolated fixtures or injected fake profiles, preserve original assets and developer objects, and remove owned fixtures afterward
