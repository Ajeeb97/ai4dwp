# Runbook - Floor 6 Document Manager Regression

## Version Header

| Field | Value |
|---|---|
| Title | Runbook - Floor 6 Document Manager Rollback |
| Version | 1.0 |
| Date | Monday morning; exact calendar date not supplied |
| Owner | IT Operations / Change Owner |
| Status | Draft for controlled incident use |
| Source | Floor-6-Monday-Incident-Response.md |

## Scope and Safety

Use this runbook only for a confirmed affected Floor 6 device after evidence capture. The rollback package, MSI product code, and application version must come from the approved change record. Do not use the commands against another floor or a device without a ticket.

## Prerequisites

1. Confirm the device is in the affected Floor 6 cohort and record its name, user, application version, and symptom.
   Expected result: The incident ticket has a unique device and user scope.
2. Use the Evidence Comparison Template to establish whether the affected device and a healthy Floor 6 comparison device show device-specific correlation with the Friday deployment.
   Expected result: The template comparison shows device-specific correlation (affected has app/events, healthy does not) or clear absence of correlation (both have similar state).
3. Confirm elevated endpoint administration and access to the approved rollback package or MSI product code.
   Expected result: The operator can run the rollback and verify its log.
4. Confirm the document-management assignment is paused for new devices.
   Expected result: No additional device enters the suspect deployment ring during the procedure.
5. Run the evidence collector in dry-run mode, then normal collection mode, before changing the device.
   Expected result: A dry-run plan is shown, followed by a timestamped evidence JSON file.
6. Confirm the user has saved work and has an approved alternate workflow.
   Expected result: No unsaved work will be lost during sign-out/restart.
7. Confirm the Copilot report, if associated with this device/user, is handled in the restricted security/privacy record.
   Expected result: No client content is copied into the endpoint remediation ticket.

## Procedure

1. Record the current time and place the device in the change's rollback scope.
   Expected result: The ticket records operator, UTC time, device, current version, and rollback reason.
2. Run `Collect-Floor6-DeviceEvidence.ps1 -DryRun`.
   Expected result: The output says `DRY-RUN` and names the evidence that would be collected; no file or device state is changed.
3. Run `Collect-Floor6-DeviceEvidence.ps1 -OutputPath 'C:\ProgramData\FinBridge\Floor6-Evidence-before.json'` as administrator.
   Expected result: The JSON file exists and contains application, sign-in event, performance, and enrollment inventory data.
4. Confirm the installed product code and supported rollback version from the approved change record.
   Expected result: The product code/version in the ticket matches the device inventory; stop if it does not.
5. Sign the user out and close the document-management application.
   Expected result: No active user session or application process is using the package.
6. Run the approved MSI rollback command: `msiexec.exe /x '{<DOCUMENT-MANAGER-MSI-PRODUCT-CODE>}' /qn /norestart /L*v 'C:\ProgramData\FinBridge\DocManager-rollback.log'`.
   Expected result: The installer returns success or the approved success code, and the verbose log records completion.
7. Restart the device from the approved endpoint-management action.
   Expected result: Windows restarts and the device remains in the held/paused deployment scope.
8. Sign in with the affected user's account and measure time from credential submission to usable desktop.
   Expected result: Authentication succeeds, the desktop loads without the reported delay, and the measured duration is recorded.
9. Check Desktop, Public Desktop, Start menu, and OneDrive Known Folder Move state.
   Expected result: Expected managed shortcuts are present or their approved source/path is documented.
10. Run the evidence collector again to `C:\ProgramData\FinBridge\Floor6-Evidence-after.json`.
    Expected result: The installed version, event state, and performance evidence reflect the post-rollback state.
11. Validate one normal document-management workflow that does not expose client data beyond the user's authorised matter.
    Expected result: The application workflow completes or the remaining failure is recorded without opening unrelated client content.
12. Add before/after evidence and user confirmation to the incident ticket.
    Expected result: The incident record supports a controlled go/no-go decision for the next device.

## Go/No-Go Gate

Proceed from one device to the three-device pilot only if all of the following are true:

- The before/after evidence files exist and every collector is marked `Success = true`, or each failed collector has a documented reason and an alternate check.
- The rollback completed with the approved return code and the log contains no unresolved error.
- Sign-in, shortcut, and approved workflow checks pass on the device.
- The device is not queued to receive the suspect application again.

Stop and keep the device isolated if any condition fails. **Reasoning:** a successful installer exit alone does not prove that the application caused the incident or that the device is safe to return to service; the gate requires both technical recovery and complete enough evidence to compare the before/after state.

## Verification

1. Repeat the procedure on three representative devices before wider expansion.
   Expected result: All three complete sign-in, desktop, shortcut, and approved workflow checks.
2. Observe the pilot devices for 30 minutes or the agreed local baseline window.
   Expected result: No recurrence of the sign-in delay, profile error, shortcut regression, or application crash signature.
3. Check Intune inventory and deployment status.
   Expected result: The devices show the intended rollback/remediation state and are not queued for the suspect version.
4. Confirm no new Floor 6 reports arrive during the observation window.
   Expected result: The incident lead records the report count and trend.
5. Return a device to normal deployment only after the change owner approves.
   Expected result: The device re-enters the approved ring, not the paused suspect ring.

## Rollback of the Rollback

Trigger this section if the device remains slow, shortcuts regress again, the application is required for an urgent workflow, or the rollback causes a new error.

1. Keep the device out of the suspect ring.
   Expected result: No automatic reinstall occurs while the failure is investigated.
2. Preserve `Floor6-Evidence-before.json`, `Floor6-Evidence-after.json`, and `DocManager-rollback.log`.
   Expected result: The change owner has the evidence needed for vendor escalation.
3. Restore the approved known-good application package only if the change owner authorises it.
   Expected result: The installation source and hash are recorded before execution.
4. Reboot and repeat the sign-in, shortcut, and workflow verification.
   Expected result: The device is either validated or remains isolated with a clear escalation note.
5. Escalate to the vendor/change owner with device, versions, timestamps, logs, and comparison-device results.
   Expected result: The escalation is actionable and does not contain unnecessary client content.
