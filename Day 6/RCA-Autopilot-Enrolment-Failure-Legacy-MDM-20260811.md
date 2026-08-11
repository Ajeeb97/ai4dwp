# Root Cause Analysis - Autopilot Enrolment Failure
## RCA-2026-0811-AP-ENROL-001 | Legacy MDM Conflict

---

## 1. Incident Summary

| Field | Detail |
|-------|--------|
| Incident ID | RCA-2026-0811-AP-ENROL-001 |
| Incident date | 2026-08-11 |
| Service | Windows Autopilot enrolment / Intune MDM onboarding |
| Affected device scope | Single device (export provided) |
| User impact | Device could not complete corporate provisioning via Autopilot |
| Severity | Medium |
| Final status | Root cause confirmed; remediation defined |

Outcome at analysis closure:
- Failure was traced to pre-existing legacy manual MDM enrolment record.
- Licensing and network were validated as healthy and excluded as primary causes.

---

## 2. Scope Facts and Analytical Constraints

The RCA is evidence-led and limited to provided export telemetry.

Confirmed scope facts:
- `EnrollmentState: Failed`
- `ErrorCode: 0x80180014`
- `ErrorDescription: The device is already enrolled in MDM`
- `MDMEnrolled: Yes (previous enrolment from 2023-11-04)`
- `EnrolmentSource: Legacy manual MDM enrolment`
- `ProfilesApplied: 0 of 4`
- `LastError: 0x80070005 (Access denied)`
- `AzureADJoined: Yes`
- `IntuneP1License: Yes`
- `AutopilotLicense: Yes`
- `Network: All endpoints reachable, no proxy`

Constraint:
- No additional event logs or portal exports were supplied in this exercise; timeline anchors are based on known dates and sequence facts.

---

## 3. Supporting Evidence

### 3.1 Enrolment Failure Evidence
- Enrolment did not complete: `EnrollmentState: Failed`.
- Primary failure indicator: `0x80180014` with explicit description: device already enrolled in MDM.

### 3.2 Conflict Evidence
- Existing enrolment explicitly present: `MDMEnrolled: Yes`.
- Historic enrolment date: `2023-11-04`.
- Existing enrolment source: `Legacy manual MDM enrolment`.

Interpretation:
- Autopilot attempted to create/complete enrolment while a conflicting pre-existing enrolment state existed.

### 3.3 Policy/Profile Application Evidence
- `ProfilesApplied: 0 of 4`.
- `LastError: 0x80070005 (Access denied)`.

Interpretation:
- Because enrolment was blocked at the identity/registration stage, policy profile application did not progress.

### 3.4 Exclusion Evidence (Non-causal)
- Azure AD join status healthy: `AzureADJoined: Yes`.
- Licensing healthy: `IntuneP1License: Yes`, `AutopilotLicense: Yes`.
- Network healthy: `All endpoints reachable, no proxy`.

Interpretation:
- Join state, licensing entitlement, and endpoint reachability do not explain this failure.

---

## 4. Timeline

| Time marker | Event | Evidence |
|-------------|-------|----------|
| 2023-11-04 | Device was manually enrolled via legacy path | `MDMEnrolled: Yes`, legacy source/date |
| Current incident window | Autopilot enrolment initiated | Incident scope |
| Current incident window | Enrolment failed with conflict state | `EnrollmentState: Failed`, `0x80180014`, explicit description |
| Current incident window | Policies/profiles did not apply | `ProfilesApplied: 0 of 4` |
| Current incident window | Access denied surfaced in downstream processing | `LastError: 0x80070005` |
| Current incident window | Join/licensing/network verified healthy | `AzureADJoined: Yes`, both licenses yes, network reachable |

---

## 5. Hypothesis Elimination Summary

1. Licensing issue
- Status: Contradicted.
- Basis: Both Intune P1 and Autopilot licenses are present.

2. Azure AD join missing or broken
- Status: Contradicted.
- Basis: `AzureADJoined: Yes`.

3. Network reachability or proxy blockage
- Status: Contradicted.
- Basis: all endpoints reachable, no proxy.

4. Existing conflicting enrolment
- Status: Supported and confirmed.
- Basis: explicit `MDMEnrolled: Yes`, legacy enrolment metadata, and `0x80180014` description.

5. Policy engine failure as primary cause
- Status: Secondary effect, not root cause.
- Basis: `0 of 4` profiles with access denied appears after enrolment conflict and is consistent with blocked progression.

---

## 6. Confirmed Root Cause

Root cause:
- A stale pre-existing legacy manual MDM enrolment record (dated 2023-11-04) conflicted with the Autopilot enrolment workflow, causing enrolment failure (`0x80180014`).

Direct technical evidence:
- Error text explicitly states device is already enrolled in MDM.
- Export confirms existing MDM enrolment and source path.

Contributing factor:
- Legacy enrolment hygiene was not completed prior to Autopilot re-enrolment attempt.

What is confirmed versus inferred:
- Confirmed: existing enrolment conflict blocked Autopilot enrolment.
- Confirmed: profile application did not progress (`0 of 4`) and access denied was present (`0x80070005`).
- Inferred (operational): stale enrolment artifacts likely remained until cleanup.

---

## 7. Five Why Analysis

Problem statement:
- Device failed to complete Autopilot enrolment.

Why 1:
- Why did Autopilot fail?
- Because enrolment state is failed with `0x80180014` and explicit already-enrolled message.

Why 2:
- Why was the device considered already enrolled?
- Because an existing MDM enrolment record was present from 2023-11-04.

Why 3:
- Why did old enrolment still exist at Autopilot time?
- Because legacy manual enrolment was not retired/deleted before new Autopilot enrolment flow.

Why 4:
- Why was pre-cleanup not done?
- Because pre-enrolment checks did not block Autopilot initiation when legacy enrolment markers existed.

Why 5:
- Why did process allow recurrence risk?
- Because there was no enforced preventative control for stale-record detection and cleanup prior to Autopilot onboarding.

Root process gap identified:
- Missing mandatory pre-flight identity/enrolment hygiene gate.

---

## 8. Resolution Plan (Confirmed Corrective Path)

1. Remove stale legacy Intune enrolment record(s).
2. Remove conflicting duplicate Entra device record(s) where applicable.
3. Confirm single authoritative Autopilot device identity and profile assignment.
4. On endpoint, remove old Work/School MDM connection and reboot.
5. Re-run Autopilot from OOBE-ready state.
6. Validate successful enrolment and full profile application.

---

## 9. Verification Criteria

Success is confirmed only when all conditions are true:
- No recurrence of `0x80180014` during enrolment.
- Device shows one authoritative active MDM enrolment.
- Profiles progress from `0 of 4` to expected applied state.
- Device check-in is healthy in Intune after enrolment.

---

## 10. Preventive Actions

1. Add mandatory pre-enrolment check:
- Block Autopilot go-live if legacy manual MDM enrolment or duplicate device object exists.

2. Add standard cleanup workflow:
- Retire/delete stale Intune record and delete stale Entra duplicates before Autopilot assignment.

3. Add recurring hygiene report:
- Weekly report for duplicate serial/hardware hash and legacy enrolment source indicators.

4. Update runbooks and triage scripts:
- Add fast-path rule: `0x80180014 + MDMEnrolled Yes` -> execute legacy-enrolment cleanup sequence.

5. Operational readiness:
- Train L1 to identify signatures and escalate early to L2/L3 for object hygiene.

---

## 11. Final RCA Statement

Based on supplied diagnostic export evidence, the Autopilot enrolment failure was caused by an existing legacy manual MDM enrolment record from 2023-11-04. This stale/conflicting enrolment prevented new Autopilot enrolment completion and blocked profile application progression. Remediation requires enrolment record hygiene in Intune/Entra plus device-side disconnection of old MDM linkage before reattempting Autopilot.
