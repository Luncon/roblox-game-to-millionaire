# Design

## Context

See proposal.md for motivation. Studio contains `Workspace.Farmer`, a 147-descendant R15 model with fifteen Motor6D joints, mesh limbs, shirt, pants, BodyColors and a hat accessory. All its parts are anchored and it has no scripts. Existing tenders are anchored procedural figures swaying beside two 56-by-40 fields. Farm I has five rows; Farm II has seven. One tender exists per farm plus one per Worker Camp tier, capped at three. SettlementInfrastructure already animates scenery from the server Heartbeat and rebuilds only when its build key/frame changes.

## Goals / Non-Goals

**Goals:** Preserve the user's rig appearance, prove continuous crop traversal and articulated walking in Studio, and keep farm economy independent of visuals.

**Non-Goals:** No animation asset dependency, active Humanoid navigation, new background tasks per worker, client-authoritative movement or profile migration.

## Decisions

- Export a clone into `assets/farm-templates/farmer.rbxmx`, mapped to `ServerStorage.FarmTemplates`. Keep the original Workspace model untouched. Sanitize runtime clones with a visual class allowlist, remove imported Humanoids/scripts/physics and external references, preserve connected body motors and cosmetic attachments. Create a fresh R15 Humanoid with EvaluateStateMachine/AutoRotate disabled, zero movement settings, no health/name display and no combat registration, solely for native clothing rendering. The user explicitly approved this exception after visual comparison showed classic clothing disappears without a Humanoid. Using the combat rig preparer was rejected because it requires R6 and creates a combat-capable Humanoid.
- Add FarmTenders to own a deterministic closed route and passive articulated rig. Rows use the existing field offsets and tier spacing. Walk slowly along each row, pause around its middle, turn at row ends, then return along a bounded field-edge route. Worker two uses the opposite field; worker three shares the first field with a phase offset. A time-sampled closed route avoids per-worker coroutines and cleans up naturally when models disappear.
- All visual parts remain anchored and noncolliding/nonqueryable. Evaluate the R15 joint chain and write part CFrames on the server, with alternating hip/shoulder swing while walking and subtle working motion during pauses. Preserve joint rest offsets and attach the hat to the head. Motor6D.Transform alone was rejected because its changes do not replicate as authoritative anchored geometry.
- Place feet on the existing soil surface, already grounded within Topography's flat rural reservation. Transform all route positions by the live Foundation frame on every update, so translated and rotated worlds work. Retain transient pose data until the rig's Destroying event clears it; reserve updates retain identity and phase. The broader Studio regression exposed that weak instance keys can disappear while the native model still exists, so weak keys cannot own live pose data.
- Keep all economy, upgrades, saved fields and combat code unchanged. Invalid/missing templates produce a clear diagnostic rather than silently importing unsafe behavior. No network API or published-client teleport check is needed for this feature.

## Risks / Trade-offs

- Anchored R15 articulation may detach accessories or misalign feet → inspect actual connections, preserve rest geometry, test joint/hat tracking and visually observe walking in Studio.
- Slow full cycles take over a minute → combine deterministic dense route samples with a real-time complete-cycle Studio observation and capture evidence.
- Up to 24 visual workers update on Heartbeat → reuse route/rig metadata and avoid allocations of instances or worker tasks per frame.
- Source assets can change → preserve original and stored template immutability, strip gameplay on every runtime clone, and regression-test malicious extra descendants.

## Migration Plan

Sync the asset mapping and managed scripts, restart the existing Studio playtest with an injected fake profile store and verify both farm tiers. Existing saves need no changes. Rollback replaces the tender module/integration and removes only the new farmer mapping/asset; preserve unrelated in-progress changes.
