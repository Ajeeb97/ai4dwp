# KB: Autopilot Enrolment Failure 0x80180014 (Legacy MDM Conflict) - L2/L3 Engineer Guide

## Version Header
- Version: 1.0
- Date: 11/08/2026
- Status: Draft

## Background
Autopilot enrolment can fail when a device has pre-existing MDM registration from an older manual enrolment process. This creates an identity/enrolment conflict and blocks fresh MDM onboarding.

## Symptom Signature
Common pattern:
- `EnrollmentState: Failed`
- `ErrorCode: 0x80180014`
- Error text indicates device already enrolled in MDM
- `MDMEnrolled: Yes` with older enrolment metadata
- `ProfilesApplied: 0 of n`
- Possible downstream `LastError: 0x80070005`

Non-causal but useful context checks:
- `AzureADJoined: Yes`
- Intune and Autopilot licenses present
- Network endpoints reachable

## Detection (Fast Path)
1. Collect MDM diagnostic export from device.
2. Confirm explicit conflict signals:
- Existing MDM enrolment present.
- Error states already enrolled.
3. In Intune admin center, search for the device by serial/device name/user and identify stale record history.
4. In Entra admin center, check for duplicate device objects tied to same physical device identity.

Proceed to remediation only when conflict pattern is confirmed.

## Resolution (Order Matters)

### Phase A - Admin center only
1. Intune admin center > Devices > All devices:
- Locate stale legacy-enrolled device record.
- Retire if still active.
- Delete stale record.

2. Intune admin center > Devices > Windows > Windows enrollment > Devices:
- Validate Autopilot identity (serial/hardware hash).
- Ensure correct profile assignment.
- Remove stale duplicates if present.

3. Entra admin center > Devices > All devices:
- Remove stale duplicate object(s) linked to legacy enrolment while preserving authoritative current identity.

### Phase B - Device access required (physical or remote)
1. Open Settings > Accounts > Access work or school.
2. Disconnect old/legacy work account linkage.
3. Reboot device.
4. Reset to OOBE-ready state per operational runbook.
5. Re-run Autopilot enrolment.

## Verification
1. Intune shows fresh successful enrolment record (current timestamp).
2. No active legacy record remains.
3. Enrolment no longer returns `0x80180014`.
4. Profile/policy application progresses from `0 of n` to expected applied state.
5. Device check-in is healthy post-enrolment.

## Rollback / Fallback
If enrolment still fails after cleanup:
1. Re-check for hidden duplicate objects in Intune/Entra.
2. Revalidate hardware hash association to correct tenant profile.
3. Recollect MDM diagnostic export and compare against this signature.
4. Escalate to platform engineering with export + object IDs + timeline.

## Preventive Standard
1. Add mandatory pre-flight gate before Autopilot assignment:
- Block onboarding when legacy enrolment or duplicate record exists.
2. Weekly hygiene report:
- Duplicate serial/hardware hash and legacy enrolment source indicators.
3. Update service desk triage template:
- Include `0x80180014` conflict pathway and immediate L2/L3 escalation.
