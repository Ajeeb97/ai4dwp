# Autopilot Enrolment Incident Communications Pack

Date: 2026-08-11  
Incident: Autopilot enrolment failure due to legacy MDM conflict  
Status: Root cause confirmed; remediation path defined

## Audience 1 - Non-technical Executive
Provisioning failed for one device because it still had an old management record from a previous enrolment method. Licensing and network were healthy, so this was not a platform outage. The corrective action is to remove the stale management record and re-run Autopilot. This is a contained issue with a clear fix and prevention action.

## Audience 2 - End-User / Team Update
Your device setup failed because it is still linked to an old company management profile. Support will remove the old link and restart setup. No action is needed from you unless support asks for a short remote or in-person session on the device.

## Audience 3 - Engineer-to-Engineer Internal Update
Summary:
- Enrolment failed with `0x80180014`.
- Export confirms `MDMEnrolled: Yes` with previous enrolment from 2023-11-04, source = legacy manual MDM enrolment.
- `ProfilesApplied: 0 of 4` and `LastError: 0x80070005` are downstream effects.
- `AzureADJoined: Yes`, Intune/Autopilot licenses present, and network healthy.

Required actions:
1. Intune record hygiene (retire/delete stale legacy record).
2. Entra duplicate object cleanup where applicable.
3. Validate Autopilot identity/profile assignment.
4. Device-side removal of old Work/School link, reboot, and Autopilot retry.

Validation target:
- No `0x80180014` on retry.
- Enrolment succeeds and profiles apply.

## Suggested Service Desk Holding Message
We identified the setup failure cause: an older management enrolment is still attached to the device. We are removing that stale record and then re-running setup. We will update you after verification is complete.
