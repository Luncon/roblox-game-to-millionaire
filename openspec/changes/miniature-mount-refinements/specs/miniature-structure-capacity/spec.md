# Spec Delta

## Purpose

Allows players to place and hold structures without arbitrary count ceilings while preserving legal space, ownership and economy rules.

## ADDED Requirements

### Requirement: No aggregate structure count cap

Settlements SHALL NOT reject a legal placement solely because twelve structures already exist. Placed structures SHALL remain limited by plot space, reserved lanes, overlap, ownership and item-specific uniqueness rules. Army capacity SHALL remain ten weighted slots regardless of structure count.

#### Scenario: Placing a thirteenth structure

- **WHEN** the owner has the item and a legal free location after twelve buildings exist
- **THEN** placement consumes one item and creates the structure
- **AND** troop buildings wait for capacity rather than increasing the army cap

### Requirement: No aggregate held-building-item cap

Held building items SHALL NOT have a fixed aggregate count limit. Valid purchases and hammer returns SHALL preserve independent item counts beyond twelve. Stock, prices, goods storage and exact finite integer validation SHALL continue to apply.

#### Scenario: Holding more than twelve building items

- **WHEN** a valid purchase or reclaim would increase held building items above twelve
- **THEN** it succeeds without a count-cap rejection
- **AND** saved counts round-trip without changing currency or another civilization

#### Scenario: Malformed saved arrays or item amounts

- **WHEN** saved structures are sparse or held amounts are invalid, fractional or numerically unsafe
- **THEN** loading rejects the malformed state without overwriting it with fresh progress
