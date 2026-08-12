# Phased Deployment Plan - FinBridge Connect v3.1

## Version Header

| Field | Value |
|-------|-------|
| Title | Phased Deployment Plan - FinBridge Connect v3.1 |
| Version | 1.0 |
| Date | 12/08/2026 |
| Author | GitHub Copilot |
| Reviewed | self |
| Status | draft |
| Change | separate structured rollout plan for Day 7 lab |

Context baseline:
- App: `FinBridge Connect v3.1` (`.intunewin`, already uploaded to Intune app catalog)
- Target fleet: `10,000` Windows 11 endpoints
- Deadline: complete within `3 weeks` from `12/08/2026`
- High-priority business group: Finance, `500` users by end of Week 1
- Hardware risk group: about `5%` of endpoints with `4 GB RAM`
- Rollback version: `FinBridge Connect v3.0` remains available in Intune
- Detection rule: registry version string check

## 1. RING STRUCTURE

1. Ring 1 (Pilot)
- Size: `150` endpoints
- Duration: `2 business days`
- Who to include:
  - `50` IT-managed validation devices
  - `50` business power users outside Finance
  - `50` standard users across two low-risk departments
- Purpose: confirm install command, uninstall command, registry detection, user launch behavior, and Intune reporting at small scale before business-priority expansion.
- Intune assignment group type to use: one `Assigned` Microsoft Entra security device group targeted with `Required` deployment.

2. Ring 2 (Early)
- Size: `1,500` endpoints
- Duration: `4 business days`
- Who to include:
  - remaining approved pilot-adjacent business units
  - non-Finance users on standard hardware
  - a capped subgroup of up to `75` carefully tracked `4 GB RAM` devices for controlled observation
- Purpose: prove the package behaves consistently at operational scale, validate support load, and confirm detection and return-code behavior under wider deployment conditions.
- Intune assignment group type to use: one `Assigned` Microsoft Entra security device group for standard hardware and one separate `Assigned` exception device group for the capped `4 GB RAM` subset, both targeted with `Required` deployment.

3. Ring 3 (Broad)
- Size: remaining `8,350` endpoints after Ring 1 and Ring 2, excluding any isolated rollback or exception devices
- Duration: `8 business days`
- Who to include:
  - all remaining eligible non-Finance devices on supported hardware
  - any deferred departments approved after Ring 2 review
  - only those `4 GB RAM` devices that passed Ring 2 performance review or have an approved exception sign-off
- Purpose: complete the enterprise rollout inside the 3-week deadline while maintaining a controlled path to isolate weak hardware or business-impacting failures.
- Intune assignment group type to use: one `Dynamic device` group or one large `Assigned` device group, depending on tenant practice, targeted with `Required` deployment; keep the `4 GB RAM` exception group excluded unless explicitly released.

4. Group design notes
- Keep Finance out of the main Ring 1 and Ring 2 path unless explicitly handled through the Week 1 priority plan in Section 4.
- Maintain a dedicated `Rollback-v3.0` assigned device group throughout the rollout.
- Maintain a dedicated `4GB-RAM-Exception` group throughout the rollout so at-risk devices can be paused without affecting standard hardware.

## 2. ADVANCE CRITERIA

1. Advance from Ring 1 to Ring 2 only when all of the following are true:
- Install success rate: at least `98.0%` of Ring 1 targeted devices show `Installed` in Intune app install status within `24 hours` of assignment.
- Error rate threshold: no more than `2.0%` of Ring 1 targeted devices show `Failed` within the same `24-hour` window.
- User-reported issues: no more than `3` FinBridge-related tickets per `100` deployed users in the first `24 hours`, measured from Service Desk tickets tagged `FinBridge Connect`.
- Monitoring period: wait at least `24 continuous hours` after `95%` of Ring 1 devices have checked in to Intune before evaluating the gate.

2. Advance from Ring 2 to Ring 3 only when all of the following are true:
- Install success rate: at least `97.0%` of Ring 2 targeted devices show `Installed` in Intune app install status within `48 hours` of assignment.
- Error rate threshold: no more than `3.0%` of Ring 2 targeted devices show `Failed` within the same `48-hour` window.
- User-reported issues: no more than `2` FinBridge-related tickets per `100` deployed users per `24-hour` period across two consecutive days.
- Monitoring period: wait at least `48 continuous hours` after `90%` of Ring 2 devices have checked in to Intune before evaluating the gate.

3. Hold condition
- Pause the next ring without full rollback if a repeatable but non-catastrophic issue appears in one device segment while the rest of the ring remains healthy.
- Specific hold trigger: pause advancement if `5` or more devices on the same Windows build or hardware model report identical app launch errors within `12 hours`, even if the overall install success rate still meets the advance threshold.
- Example: Ring 2 reaches `97.8%` Installed, but `6` devices on a single OEM model fail to launch FinBridge Connect after install. Hold Ring 3, isolate that model in an exception group, and continue root-cause analysis before resuming.

4. Measurement sources
- Use Intune app install status for `Installed`, `Failed`, and `Not applicable` counts.
- Use Service Desk ticket counts filtered by `FinBridge Connect` tag and assignment window.
- Use device segmentation reporting for the `4 GB RAM` exception group.

## 3. ROLLBACK TRIGGERS

1. Install failure rate rollback trigger
- Trigger: halt rollout and initiate rollback if more than `5.0%` of devices in the active ring show `Failed` status within any rolling `6-hour` window after assignment.
- Rollback decision maker: Endpoint Engineering lead with approval from the DWP service owner.
- Decision window: within `60 minutes` of the trigger being confirmed.
- Exact Intune action:
  - remove the active ring device group from `FinBridge Connect v3.1` `Required` assignments
  - add the same device group to `FinBridge Connect v3.0` `Required` assignments through the `Rollback-v3.0` group
  - keep the affected ring excluded from any further `v3.1` assignments until review completes

2. Application crash rate rollback trigger
- Trigger: move to rollback consideration if `2.0%` or more of successfully installed devices in the active ring generate confirmed FinBridge application crash events within `24 hours` of install.
- Rollback decision maker: Endpoint Engineering lead, Application owner, and Major Incident Manager together.
- Decision window: within `2 hours` of the threshold being reached.
- Exact Intune action:
  - pause further `v3.1` group assignments immediately
  - if the joint review confirms business impact, swap the affected ring from `v3.1 Required` to `v3.0 Required` using the existing rollback assignment group

3. Business-critical failure rollback trigger
- Trigger: immediate rollback regardless of percentage if Finance users cannot complete a core payment approval or settlement workflow in FinBridge Connect after the upgrade.
- Rollback decision maker: Finance service owner and DWP service owner jointly, with the Endpoint Engineering lead executing.
- Decision window: within `30 minutes` of reproduction on one production Finance device.
- Exact Intune action:
  - remove the Finance-targeted `v3.1` assignment group from `Required`
  - assign the Finance rollback group to `FinBridge Connect v3.0` as `Required`
  - keep Finance excluded from all further `v3.1` waves pending defect review

4. `4 GB RAM` device isolation trigger
- Trigger: isolate the at-risk hardware group if `10.0%` or more of assigned `4 GB RAM` devices show `Failed` status or severe performance tickets within `24 hours` of assignment.
- Rollback decision maker: Endpoint Engineering lead.
- Decision window: within `4 hours` of threshold confirmation.
- Exact Intune action:
  - remove the `4GB-RAM-Exception` group from all `v3.1 Required` assignments
  - assign only that exception group to `FinBridge Connect v3.0 Required`
  - continue the main ring only for standard-hardware groups if they remain inside thresholds

5. Operational rule
- A halt means no new ring assignments are added.
- A rollback means the affected group is actively retargeted from `v3.1` to `v3.0` in Intune, not merely left unassigned.

## 4. FINANCE DEADLINE RESOLUTION

1. Option A - compress the pilot ring timeline to fit Finance into Ring 2 by end of Week 1
- Minimum safe pilot duration: `1 business day` with at least `24 continuous hours` of monitoring after most pilot devices check in.
- Risk introduced: one day of pilot data is enough to confirm packaging and detection issues, but not enough to expose slower-burn problems such as intermittent launch failures, support volume spikes, or device-model-specific regressions.
- Compensating control: require hourly review of Intune status and Service Desk tickets during the compressed pilot and cap Finance early deployment to `100` users on standard hardware before the remaining `400` are released.

2. Option B - treat Finance as a separate priority Ring 0 before the main pilot
- Ring 0 structure:
  - size: `100` Finance endpoints on standard hardware only
  - duration: `2 business days`
  - assignment group: one `Assigned` Entra security device group targeted with `Required`
  - exclusions: all known `4 GB RAM` Finance devices remain excluded initially
- Ring 0 advance conditions:
  - at least `98.0%` Installed within `24 hours`
  - no more than `2.0%` Failed within `24 hours`
  - no more than `2` Finance workflow-impacting tickets per `100` users in the first `24 hours`
  - no confirmed failure of payment approval or settlement workflow
- Ring 0 rollback plan:
  - if the Finance workflow blocker is reproduced once, remove the Ring 0 group from `v3.1 Required` and assign the same group to `v3.0 Required` within `30 minutes`
  - if Ring 0 exceeds `5.0%` Failed in `6 hours`, halt further Finance release and retarget Ring 0 to `v3.0`
  - if Ring 0 passes, deploy the remaining `400` Finance users in two batches of `200` across the rest of Week 1 while the main Ring 1 for non-Finance users proceeds in parallel

3. Recommendation
- Recommend Option B.
- Justification: Finance is a business-priority group with a fixed Week 1 deadline, so it should be treated as a controlled priority wave rather than forced into a compressed generic pilot. Option B protects the deadline and still preserves risk control by using a Finance-specific Ring 0, explicit workflow-based rollback triggers, and exclusion of `4 GB RAM` devices until performance is proven. Option A is workable, but it trades away observation time across the whole pilot population just to fit Finance into the generic ring sequence, which creates more systemic risk for the remaining `9,500` endpoints.

4. Recommended execution sequence
- Days 1-2: run Finance Ring 0 on `100` standard-hardware Finance devices.
- Days 3-5: complete the remaining `400` Finance users in controlled batches if Ring 0 passes.
- In parallel, run main Ring 1 for non-Finance pilot users.
- Week 2: run Ring 2 early deployment for non-Finance users and capped `4 GB RAM` observation group.
- Week 3: run Ring 3 broad deployment and finish approved exceptions.