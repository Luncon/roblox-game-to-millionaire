# Combat Rewards

## Purpose

Connect legitimate battlefield victories to the attacking civilization's currency without trusting client kill claims.

## ADDED Requirements

### Requirement: Final hit earns ten coins
The civilization whose player or troop delivers a validated hostile killing blow SHALL receive 10 coins. Earlier attackers SHALL receive no assist reward. A victim life SHALL reward at most once; rewards SHALL not exceed the currency cap.

#### Scenario: Troop finishes an enemy
- **WHEN** a troop's validated attack reduces an enemy NPC or player from living to dead
- **THEN** its connected civilization owner receives 10 coins and updated HUD currency
- **AND** duplicate damage or death notifications cannot award again

#### Scenario: Another civilization lands the final hit
- **WHEN** several civilizations damage a victim and one delivers the final hit
- **THEN** only that final attacker's civilization receives the reward

### Requirement: Invalid deaths never reward
Friendly hits, self-hits, neutral targets, protected settlements, blocked damage, environmental deaths, and stale departed-owner attacks SHALL not generate kill rewards.

#### Scenario: Environmental death after earlier damage
- **WHEN** a previously damaged actor later dies without a validated killing blow
- **THEN** no civilization receives coins for that death
