# Evidence Comparison Template - Floor 6 Incident

## Version Header

| Field | Value |
|---|---|
| Version | 1.0 |
| Date | Monday morning; exact calendar date not supplied |
| Owner | Incident lead / L2 engineer |
| Source | Floor-6-Document-Manager-Rollback-Runbook.md, Runbook Prerequisite Step 2 |

## Purpose

Use this template to compare evidence from an affected Floor 6 device with a healthy comparison device. The comparison determines whether the Friday document-management deployment is the likely common cause (Runbook Prerequisite Step 2 decision point).

## Device Selection

- **Affected device:** received the Friday document-management deployment, shows slow sign-in or missing shortcuts, has a ticket and evidence collection completed.
- **Healthy comparison device:** physically on Floor 6, same Win11 baseline, same model/RAM where possible, does NOT show the reported symptoms, device name and Intune enrollment status recorded.

## Comparison Matrix

Run `Collect-Floor6-DeviceEvidence.ps1` on both devices and complete the matrix below:

| Evidence field | Affected device | Healthy device | Match? | Interpretation |
|---|---|---|---|---|
| `Collections[Application].Success` | Yes/No | Yes/No | Y/N | If affected is False but healthy is True, check access/permissions. If both False, the collector issue is not device-specific. |
| Application DisplayVersion | (e.g., 2.1.0) | (e.g., none or 2.0.0) | Y/N | If versions differ, the deployment is device-specific. |
| Application InstallDate | (UTC timestamp) | (N/A or earlier date) | Y/N | If affected date is after Friday 17:00 and healthy is before or missing, the deployment preceded symptoms. |
| `Collections[SignInEvents].Success` | Yes/No | Yes/No | Y/N | If both False, the event log may not be accessible on this hardware; note and proceed to next field. |
| SignInEvents count (last 4 hours) | (count) | (count) | Y/N | If affected >> healthy, sign-in processing is more frequent/slower on affected device. |
| Event ID 4624 (logon) delay pattern | (timestamps spaced X sec apart) | (timestamps spaced Y sec apart) | Y/N | If affected logons are much slower (X >> Y), profile/policy processing is delayed. |
| `Collections[Performance].Success` | Yes/No | Yes/No | Y/N | If both False, performance counters may not be readable; note and proceed. |
| Disk Transfers/sec (average) | (value) | (value) | Y/N | If affected >> healthy during collection, disk I/O is elevated. |
| Processor % (average) | (value) | (value) | Y/N | If affected >> healthy, CPU is working harder during baseline. |
| Memory Available MBytes (average) | (value) | (value) | Y/N | If affected << healthy, memory pressure is higher. |
| `Collections[IntuneRegistry].Success` | Yes/No | Yes/No | Y/N | If both False, enrollment may be broken on this hardware; escalate. |
| EnrollmentType | (value) | (value) | Y/N | Both should show MDM; if not, investigate enrollment state. |
| LastSyncTime | (UTC timestamp) | (UTC timestamp) | Y/N | Both should be recent (within last 4 hours); if affected is older, enrollment check-in may be blocked. |

## Correlation Summary

Complete this section after filling the matrix:

### Deployment correlation

- **Application installed on affected device:** Yes / No / Unclear
- **Same application version not on healthy device:** Yes / No / Unclear
- **Installation preceded symptoms by < 2 hours:** Yes / No / Unclear

**Go decision:** If all three are Yes, proceed with Runbook rollback on affected device.

**Stop decision:** If any is No or Unclear, preserve evidence and escalate to change owner with the matrix.

### Event/Performance correlation

- **Event collection shows elevated logon frequency or delay on affected device:** Yes / No / Unclear
- **Performance counters show elevated disk I/O or CPU on affected device during baseline:** Yes / No / Unclear

**Supporting evidence:** If yes to either, the deployment or its side effects are correlated with the symptoms.

**Contradicting evidence:** If no to both, the deployment may not be the cause; investigate alternative hypotheses (Intune policy, network, security agent).

### Enrollment health

- **Both devices enrolled and syncing normally:** Yes / No
- **Affected device enrollment is stale or disconnected:** Yes / No

**Action:** If affected device enrollment is stale, run Intune compliance check before rollback.

## Example Completed Row

| Application DisplayVersion | 2.1.0 | 2.0.0 | N | Affected device has the new version; healthy device has the previous stable version. Deployment is device-specific. |

## Sign-off

- Comparison completed by: ________________
- Date/time: ________________
- Affected device name: ________________
- Healthy device name: ________________
- **Go/Stop decision:** Go / Stop / Escalate
- Reason: ________________
- Change owner approval: ________________

## Escalation Criteria

Stop and escalate to the change owner if:

- Evidence collection failed on both devices (suggests hardware or OS issue, not app).
- Both devices have the application installed but only one is slow (suggests user/profile-specific issue, not app).
- Affected device enrollment is broken and cannot check policy/compliance.
- The comparison is ambiguous (e.g., both devices have similar performance, but affected has the application).
