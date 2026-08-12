# Deployment Plan - FinBridge Connect v3.1

## Version Header

| Field | Value |
|-------|-------|
| Title | Deployment Plan - FinBridge Connect v3.1 |
| Version | 1.0 |
| Date | 12/08/2026 |
| Author | GitHub Copilot |
| Reviewed | self |
| Status | draft |
| Change | initial deployment plan for Day 7 lab |

## 1. Deployment Summary

- Application: `FinBridge Connect v3.1` (`.intunewin`)
- Endpoint estate: `10,000` Windows 11 devices
- Rollout deadline: `3 weeks` from `12/08/2026`
- Highest priority audience: Finance team, `500` users, complete by end of Week 1
- Known device risk: about `5%` of endpoints have older hardware with `4 GB RAM`
- Previous production version: `FinBridge Connect v3.0`
- Rollback option: `v3.0` remains available in Intune app catalog
- Detection rule: registry version string check

## 2. Objectives

1. Deliver `v3.1` to Finance users by the end of Week 1 with controlled blast radius.
2. Complete broad enterprise rollout inside the 3-week deadline.
3. Minimize disruption on lower-spec devices through pre-targeting and phased assignment.
4. Preserve fast rollback to `v3.0` using existing Intune packaging.

## 3. Key Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `4 GB RAM` devices perform poorly on `v3.1` | User experience degradation, increased tickets | Medium | Pre-identify low-spec devices and defer them to a controlled later wave |
| Finance deadline slips | Business disruption in Week 1 | Medium | Reserve first wave capacity for Finance only and use extended monitoring during first 48 hours |
| Detection rule mismatch | False install state, repeat installs, failed remediation | Medium | Validate registry path/value on test devices before pilot approval |
| Broad deployment regression | Large-scale user impact | Low/Medium | Use phased rings and keep `v3.0` assigned as rollback package |

## 4. Rollout Strategy

### Ring 0 - Validation
- Scope: `10-20` IT-managed test devices
- Timing: Day 1
- Exit criteria:
  - App installs successfully from Company Portal or required assignment
  - Registry detection reports expected `v3.1` value
  - Launch test passes on both standard and finance-user profiles
  - No abnormal RAM or startup impact observed

### Ring 1 - Finance Pilot
- Scope: `100` Finance users on supported hardware
- Timing: Day 2
- Exit criteria:
  - Install success rate at or above `98%`
  - No Sev1/Sev2 incidents
  - No pattern of instability on finance workflows

### Ring 2 - Finance Broad
- Scope: remaining `400` Finance users
- Timing: Days 3-5
- Exit criteria:
  - Finance deployment complete by end of Week 1
  - Rollback not required for more than `2%` of deployed devices

### Ring 3 - Enterprise Pilot
- Scope: `1,000-1,500` non-Finance users
- Timing: Week 2
- Exit criteria:
  - Install success rate remains at or above `98%`
  - Low-spec device exception handling is effective

### Ring 4 - Enterprise Broad
- Scope: remaining supported estate
- Timing: Weeks 2-3
- Exit criteria:
  - Overall deployment completed before deadline
  - Support volumes remain within agreed threshold

## 5. Device Segmentation

1. Build dynamic Intune groups for:
- Finance users on supported hardware
- Finance users on `4 GB RAM` devices
- Non-Finance users on supported hardware
- Non-Finance users on `4 GB RAM` devices

2. Exclude low-spec devices from initial required deployment until pilot data confirms acceptable performance.

3. Keep a dedicated rollback group that can be rapidly targeted with `v3.0`.

## 6. Change Controls

1. Validate package metadata, install command, uninstall command, return codes, and supersedence behavior in Intune.
2. Confirm registry detection path, value name, and version string on `v3.0` and `v3.1` devices before production assignments.
3. Freeze unrelated app changes for Finance devices during Week 1 deployment window.
4. Publish support and escalation path before Ring 1 starts.

## 7. Monitoring Plan

Track these measures for each ring:
- Install success rate
- Detection success rate
- Retry/failure count
- Helpdesk ticket volume tagged `FinBridge Connect`
- Device performance reports for low-spec endpoints
- Rollback count to `v3.0`

## 8. Go/No-Go Criteria

Go forward only if all are true:
1. Ring 0 validates install, launch, uninstall, and detection.
2. Registry detection is consistent across fresh install and upgrade scenarios.
3. Rollback to `v3.0` succeeds on at least one test endpoint.
4. Finance support team confirms readiness for Week 1 coverage.

## 9. Fallback Decision Triggers

Pause rollout and assess rollback if any of these occur:
1. Install success rate drops below `95%` in any production ring.
2. Finance-critical workflow failure is confirmed.
3. Low-spec devices show sustained unusable performance.
4. Detection rule reports widespread false positives or false negatives.

## 10. Recommended Timeline

| Window | Activity |
|--------|----------|
| Day 1 | Ring 0 validation and rollback test |
| Day 2 | Finance pilot (`100` users) |
| Days 3-5 | Finance broad rollout (`400` users) |
| Week 2 | Enterprise pilot and low-spec review |
| Week 3 | Broad deployment completion and exception cleanup |

## 11. Notes

- Do not include `4 GB RAM` devices in the first Finance wave unless explicitly validated.
- Prefer required deployment for broad rings and available deployment for isolated remediation testing.
- Keep `v3.0` active in Intune until post-rollout stabilization is complete.