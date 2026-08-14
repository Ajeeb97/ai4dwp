# KB-L2 - Floor 6 Document Manager Regression

## Version Header

| Field | Value |
|---|---|
| Version | 1.0 |
| Date | Monday morning; exact calendar date not supplied |
| Audience | L2/L3 endpoint and Intune engineers |
| Source | Floor-6-Document-Manager-Rollback-Runbook.md |
| Owner | IT Operations / Change Owner |

## Trigger and scope

Use this article when a Floor 6 device received the Friday document-management deployment and shows slow sign-in, profile/shell delay, missing managed shortcuts, or a related application failure. It is a technical re-expression of the runbook: Prerequisites 1-7 establish scope and evidence gate; Procedure 1-4 establish evidence and confirm compatibility; Procedure 5-7 perform the controlled rollback; Procedure 8-12 verify the result; Verification 1-5 governs expansion. Confirm the device and version in the incident record before acting.

## Evidence

Run as administrator from the local script path:

```powershell
.\Collect-Floor6-DeviceEvidence.ps1 -DryRun
.\Collect-Floor6-DeviceEvidence.ps1 -OutputPath 'C:\ProgramData\FinBridge\Floor6-Evidence-before.json'
```

Review installed application entries in both native and WOW6432Node uninstall paths; recent User Profile Service, Group Policy, and Winlogon events; performance samples; and Intune enrollment inventory. Capture the application version, install time, sign-in duration, device name, user, and exact event timestamps. Compare at least one healthy device.

## Controlled rollback

1. Confirm the approved MSI product code and package from the change record.
2. Confirm the deployment assignment is paused for new devices.
3. Save user work and sign out.
4. Run elevated:

```powershell
msiexec.exe /x '{<DOCUMENT-MANAGER-MSI-PRODUCT-CODE>}' /qn /norestart /L*v 'C:\ProgramData\FinBridge\DocManager-rollback.log'
```

5. Reboot through approved endpoint management.
6. Run the collector to `Floor6-Evidence-after.json`.
7. Validate sign-in duration, Desktop/Public Desktop/Start shortcuts, OneDrive Known Folder Move state, and one authorised document workflow.

Do not substitute an unverified uninstall string. If the app is not MSI-based, use the signed vendor rollback package and record its hash and return code.

## Verification and expansion

This is Runbook Verification 1-5 expressed as an engineer's gate: pilot one device, then three representative devices. Require successful sign-in, correct shortcuts, healthy Intune state, no repeat profile/application errors during the observation window, and user confirmation. Keep the device out of the suspect ring until the change owner approves re-entry.

## Failure handling

This is Runbook Rollback of the Rollback Steps 1-5: preserve before/after JSON and the rollback log, keep the device isolated from the suspect ring, and escalate with comparison-device results. Do not wipe the profile or device before evidence review unless an approved security or recovery procedure requires it.

## Copilot boundary

Do not include client matter content in this ticket. A report of unexpected Copilot content belongs in the restricted security/privacy record. Preserve the object identifier, effective permissions, sensitivity label, group path, prompt/response, and audit correlation; do not reproduce against the live matter.
