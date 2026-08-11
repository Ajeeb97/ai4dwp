# Analysis and Resolution - Autopilot Enrolment Failure (Legacy MDM Conflict)
**Author:** DWP Analyst  
**Date:** 2026-08-11  
**Incident Type:** Windows Autopilot enrolment failure  
**Final Status:** Root cause confirmed, remediation defined

---

## 1. Executive Summary
Autopilot enrolment failed because the device already had an existing legacy manual MDM enrolment record dated 2023-11-04. The active/stale prior enrolment conflicted with the new Autopilot-driven MDM enrolment attempt.

Confirmed failure data:
- `EnrollmentState: Failed`
- `ErrorCode: 0x80180014`
- `ErrorDescription: The device is already enrolled in MDM`
- `MDMEnrolled: Yes (previous enrolment from 2023-11-04)`
- `ProfilesApplied: 0 of 4`
- `LastError: 0x80070005 (Access denied)`
- `AzureADJoined: Yes`
- `IntuneP1License: Yes`
- `AutopilotLicense: Yes`
- `Network: All endpoints reachable, no proxy`

Conclusion:
- Licensing and network were not blockers.
- Primary blocker was conflicting pre-existing MDM enrolment.

---

## 2. Confirmed Root Cause
Root cause is a legacy manual MDM enrolment record still associated with the device. Autopilot cannot complete while a conflicting MDM enrolment exists.

Error code handling in this analysis:
- `0x80180014`: treated as provided and confirmed by export text (already enrolled in MDM).
- `0x80070005`: treated as provided and confirmed by export text (access denied during downstream profile/policy operations).

---

## 3. Remediation Steps (Exact), With Access Flags

### A. Intune admin center cleanup (Admin center only)
1. Sign in to Intune admin center.
2. Go to **Devices > All devices**.
3. Search using serial number, device name, and user to find all records tied to this endpoint.
4. Open the stale/legacy enrolled record (expected enrolment history from 2023-11-04).
5. If the device is still actively managed in that old record, run **Retire** first.
6. After retire completes (or immediately if stale/offline), run **Delete** on the stale Intune device record.
7. Go to **Devices > Windows > Windows enrollment > Devices (Windows Autopilot)**.
8. Verify the Autopilot device identity exists (correct serial/hardware hash) and is assigned to the intended deployment profile.
9. If duplicate or conflicting records exist in Autopilot or Intune, retain only the authoritative current record and remove stale duplicates.

### B. Entra device object hygiene (Admin center only)
1. Open Microsoft Entra admin center.
2. Go to **Devices > All devices**.
3. Search same serial/device identity indicators.
4. Remove stale duplicate device objects that correspond to the old manual MDM enrolment while preserving the intended current identity used by Autopilot.

### C. Device-side cleanup and re-enrolment preparation (Device access required: physical or remote)
1. Sign in to the device with local admin or approved support account.
2. Open **Settings > Accounts > Access work or school**.
3. Disconnect old/legacy work or school connection associated with prior manual enrolment.
4. Reboot the device.
5. Reset to Autopilot-ready state (approved method in your runbook):
   - Preferred for clean reprovisioning: Windows reset to OOBE state.
6. Start OOBE, connect to network, and proceed with corporate sign-in so Autopilot can perform fresh enrolment.

---

## 4. Correct Order of Operations
Follow this order exactly to avoid reintroducing stale identity state:

1. Admin center only: Remove stale Intune MDM enrolment record(s).
2. Admin center only: Remove stale duplicate Entra device object(s) tied to the legacy enrolment.
3. Admin center only: Confirm Autopilot identity and profile assignment are correct.
4. Device access required: Disconnect old Work/School enrolment on endpoint.
5. Device access required: Reboot and reset to OOBE/autopilot-ready state.
6. Device access required: Re-run Autopilot enrolment flow.
7. Admin center only: Validate successful enrolment and policy/profile application.

---

## 5. Verification Checks After Remediation

### A. Intune validation (Admin center only)
1. In **Devices > All devices**, confirm device appears as newly enrolled and managed by Intune.
2. Confirm enrolment timestamp is current (post-remediation) and legacy 2023-11-04 record is no longer active.
3. Confirm profile/policy deployment progresses from `0 of 4` to expected completion.
4. Confirm device check-in is current and no active enrolment conflict errors remain.

### B. Device state validation (Device access required: physical or remote)
1. In **Settings > Accounts > Access work or school**, confirm only the expected current org connection exists.
2. Run `dsregcmd /status` and confirm Azure AD join remains valid and MDM URL fields are populated for active management.

### C. Success criteria
Autopilot remediation is successful when all are true:
- Enrolment completes without `0x80180014` recurrence.
- MDM shows active single authoritative enrolment.
- Assigned profiles/policies apply successfully.
- Device shows healthy check-ins with no access denied block in enrolment workflow.

---

## 6. Preventive Action (To Stop Recurrence)
Implement a pre-enrolment legacy-enrolment gate in the standard Autopilot process:

1. Before importing/assigning Autopilot devices, run a mandatory check for existing legacy/manual MDM enrolments and duplicate device records.
2. If legacy enrolment exists, perform cleanup (retire/delete stale records in Intune and duplicates in Entra) before Autopilot assignment.
3. Add this as a hard prerequisite in the L2/L3 runbook and service desk triage checklist.
4. Add periodic reporting (weekly) for devices with:
   - Multiple records by serial/hardware hash
   - Old manual MDM enrolment source
   - Enrolment conflict indicators
5. Train frontline teams to identify this signature quickly:
   - `0x80180014` + existing MDM enrolment history + profiles not applying.

---

## 7. Final Analyst Statement
Based on the collected export data and completed analysis, the root cause is confirmed as a stale conflicting legacy manual MDM enrolment record from 2023-11-04. The remediation above removes the conflicting record path, preserves correct Autopilot identity, and restores a clean enrolment sequence.
