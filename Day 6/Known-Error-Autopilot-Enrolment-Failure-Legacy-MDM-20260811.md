# Known Error Record - Autopilot Enrolment Failure (Legacy MDM Conflict)

Symptom:
- Autopilot enrolment fails.
- Typical indicators: `EnrollmentState: Failed`, `ErrorCode: 0x80180014`, profiles remain unapplied.

Cause:
- Device has an existing legacy manual MDM enrolment record, creating a conflict with new Autopilot enrolment.

Scope:
- Devices previously manually enrolled in MDM and later onboarded/re-onboarded through Autopilot without stale record cleanup.

How to spot it quickly:
- `ErrorDescription` explicitly says device is already enrolled in MDM.
- `MDMEnrolled: Yes` with historical enrolment date/source.
- `ProfilesApplied` remains low or `0 of n`.
- `LastError` may include access-denied outcomes during downstream policy operations.

Immediate workaround:
- Pause repeated Autopilot retries.
- Escalate to L2/L3 for enrolment-object hygiene in Intune and Entra.

Permanent fix:
1. Remove stale legacy Intune MDM enrolment records.
2. Remove stale duplicate Entra device objects.
3. Ensure one authoritative Autopilot identity/profile assignment.
4. Disconnect old Work/School account on device and reboot.
5. Re-run Autopilot from OOBE-ready state.

Validation:
- No recurrence of `0x80180014`.
- Device shows current active enrolment only.
- Assigned profiles/policies apply successfully.

Preventive control:
- Enforce a pre-enrolment gate to block Autopilot if legacy MDM record or duplicate identity exists.
