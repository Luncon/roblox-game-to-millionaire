# Civilization claims

## Purpose

Let players choose a prototype civilization and receive one settlement plot,
with exclusive server-owned claims and understandable selection feedback.

## ADDED Requirements

### Requirement: Server-owned exclusive claims

The server SHALL accept only supported civilization identifiers, allow at most
one owner per civilization and one plot per player, and assign distinct available
plots. Invalid, conflicting, and capacity-exceeding requests SHALL leave claims unchanged.

#### Scenario: Two players request the same civilization

- **WHEN** two unclaimed players request Sparta in the same server
- **THEN** only one receives Sparta and a plot
- **AND** the other receives an unavailable response without losing access to Britain

#### Scenario: Claim distinct civilizations

- **WHEN** different players successfully select Sparta and Britain
- **THEN** they own different plots and the same ownership is visible to all clients

#### Scenario: Reject malformed or unsupported requests

- **WHEN** a request contains a non-string or unsupported civilization identifier
- **THEN** the server rejects it without creating or changing a claim

#### Scenario: Repeat or change an existing claim

- **WHEN** an owner requests their civilization again or requests another civilization
- **THEN** their original plot remains theirs without a second allocation
- **AND** a different civilization request is rejected until they leave

#### Scenario: No settlement capacity remains

- **WHEN** no plot is free and another player requests a civilization
- **THEN** the server returns a full response without exceeding the configured plot count

### Requirement: Claim lifecycle and spawning

Accepted claims SHALL move the player to their plot, survive character respawns,
and release their civilization and plot when the player leaves the server.

#### Scenario: Respawn after claiming

- **WHEN** an owner resets their character
- **THEN** they retain their civilization and respawn at the same plot

#### Scenario: Owner departs

- **WHEN** an owner leaves
- **THEN** another player can claim the released civilization and plot

### Requirement: Clear selection states

The selection UI SHALL show Sparta and Britain, live availability, a pending
state, actionable rejection feedback, and the player's claimed civilization and
plot. It SHALL explain that this prototype does not save progress.

#### Scenario: Select an available civilization

- **WHEN** the player activates an available choice
- **THEN** further selections are disabled while the request is pending
- **AND** the UI shows the server-confirmed civilization and plot after acceptance

#### Scenario: Availability changes or a request fails

- **WHEN** another player claims or releases a civilization, or a selection request fails
- **THEN** the UI refreshes its choices or shows retry guidance
- **AND** it never displays a client-predicted claim as confirmed ownership

### Requirement: Input and small-screen support

Civilization choices SHALL support mouse, touch, and gamepad activation, use
text to distinguish availability, and remain usable at a 320-pixel viewport width.

#### Scenario: Select using alternate input or a small screen

- **WHEN** a player uses touch or gamepad activation, or views a narrow viewport
- **THEN** the available choices and feedback remain readable and operable

### Requirement: Bound client requests

The server SHALL bound the frequency of selection requests from each player
and reject excessive requests without changing ownership or creating new objects.

#### Scenario: Rapid requests

- **WHEN** a player repeatedly sends selection requests faster than the accepted rate
- **THEN** excess requests are rejected and existing claims remain consistent
