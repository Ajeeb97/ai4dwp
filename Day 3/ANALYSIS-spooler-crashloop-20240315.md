# Service Crash Loop Analysis — Print Spooler
## INC-2024-0315-SVC001 | Print Spooler | System Event Log

---

## 1. Incident Summary

| Field | Detail |
|-------|--------|
| **Incident ID** | INC-2024-0315-SVC001 |
| **Date / Time** | 2024-03-15, 10:01 – 10:03 (local time) |
| **Affected Service** | Print Spooler (spoolsv.exe) |
| **Configured Account** | NT AUTHORITY\SYSTEM |
| **Crash Count** | 4 unexpected terminations within 2 minutes |
| **Outcome** | Service in crash loop; ultimately unable to restart |
| **Severity** | High — all printing unavailable on the endpoint |

---

## 2. Event Log Entries — Reference

### Event ID 7034 — Service Terminated Unexpectedly (Source: Service Control Manager)

Generated each time a service process exits without the Service Control Manager (SCM) having requested the stop. The SCM tracks a running count of unexpected terminations per service session. This event fires when **no recovery action is configured** for the current failure count, or when the service fails before recovery kicks in.

Three instances recorded:

| Time | Termination Count |
|------|------------------|
| 10:01:14 | 1st |
| 10:01:45 | 2nd |
| 10:02:16 | 3rd |

**Interval between crashes: ~31 seconds each.** This regularity indicates the SCM's restart delay between attempts is set to approximately 30 seconds for the first three failures.

---

### Event ID 7031 — Service Terminated Unexpectedly with Recovery Action (Source: Service Control Manager)

Functionally identical to 7034 but generated specifically when a **recovery action is configured** for this failure count. Records what corrective action the SCM will take and after how long.

| Time | Termination Count | Recovery Action |
|------|------------------|-----------------|
| 10:02:47 | 4th | Restart the service in **60,000 ms (60 seconds)** |

This event signals the SCM has now escalated to its configured third-failure recovery rule. The 60-second delay means the next restart attempt would fire around **10:03:47**.

---

### Event ID 7023 — Service Terminated with Error (Source: Service Control Manager)

Generated when a service terminates and reports a specific Win32 error code as the reason for failure. This is distinct from 7034/7031 (which record unexpected termination without an error code).

| Time | Error | Meaning |
|------|-------|---------|
| 10:03:49 | The specified module could not be found | Win32 error `ERROR_MOD_NOT_FOUND` (126) — a DLL or module that the service requires could not be located in the search path |

This event fires approximately at the time the 60-second recovery restart was due (10:03:47). The service attempted to restart but immediately terminated when it could not load a required module.

**This is the proximate technical cause of the crash loop.** The Print Spooler (spoolsv.exe) loads printer driver DLLs on startup. If a driver's DLL has been deleted, is corrupt, or its registered path is wrong, the Spooler will fail to initialise and terminate immediately with this error — causing the cycle to repeat indefinitely.

---

### Event ID 7038 — Service Unable to Log On (Source: Service Control Manager)

Generated when the SCM cannot authenticate the service's configured logon account, or when the account does not have the required logon rights.

| Time | Configured Account | Error |
|------|--------------------|-------|
| 10:03:50 | NT AUTHORITY\SYSTEM | Logon failure: the user has not been granted the requested logon type at this computer |

**This event fires 1 second after 7023, during the same restart attempt.**

`NT AUTHORITY\SYSTEM` is the Windows local system account and normally requires no special configuration to log on as a service — it is implicitly trusted above all other accounts. The appearance of this error for SYSTEM is therefore anomalous and indicates one of the following:

- A **Group Policy** (local or domain) is explicitly restricting the "Log on as a service" (`SeServiceLogonRight`) or "Log on locally" right, and SYSTEM has been incorrectly excluded.
- The Print Spooler service's **logon account was changed** away from SYSTEM (to a named account or managed service account), and then changed back, leaving the SCM with inconsistent or stale credential data.
- A **security hardening script or policy** was applied that modified the User Rights Assignment in the local security policy and inadvertently affected SYSTEM.

---

## 3. Sequence of Events — Narrative

**10:01:14** — The Print Spooler service crashes for the first time and terminates without warning. The SCM logs the first unexpected termination (7034). A recovery restart fires after the configured delay (~30 seconds).

**10:01:45** — The Spooler restarts but crashes again almost immediately. Second unexpected termination (7034). Recovery restart fires again.

**10:02:16** — Third crash. Same pattern. (7034).

**10:02:47** — Fourth crash. The SCM now applies its escalated recovery rule — it will wait 60 seconds before the next restart attempt and logs this with corrective action detail (7031).

**10:03:47** *(approximate)* — The SCM attempts to restart the Spooler per its recovery schedule.

**10:03:49** — The restarting Spooler immediately terminates with a specific error: a required DLL or module cannot be found (7023, `ERROR_MOD_NOT_FOUND`). This reveals why every previous restart also failed — the module was missing from the first crash onward.

**10:03:50** — The SCM also reports it cannot log the Spooler on as `NT AUTHORITY\SYSTEM` due to a logon type restriction (7038). The service is now unable to start at all and enters a permanently failed state until manual intervention.

---

## 4. Root Cause Assessment

**Two distinct faults are present, both of which must be resolved:**

---

### Fault 1 — Missing or Corrupt Printer Driver DLL (Primary — causes the crash loop)

**Event:** 7023 — `ERROR_MOD_NOT_FOUND`

The Print Spooler cannot locate a module it requires on startup. In the overwhelming majority of Spooler crash-loop cases with this error code, the cause is:

- A printer driver DLL that is registered in the Spooler's driver database but whose file has been deleted, moved, or corrupted (e.g., following a failed driver update, a forced driver removal, or antivirus quarantine action).
- A third-party monitoring or print management agent that removed a driver without correctly cleaning up the registry entries.
- Driver store corruption following a Windows Update or rollback.

The crash is **deterministic** — every Spooler start attempt hits the same missing module, which is why the crash interval is consistent and recovery never succeeds.

---

### Fault 2 — SYSTEM Logon Type Restriction (Secondary — prevents service startup entirely after recovery)

**Event:** 7038 — Logon failure for `NT AUTHORITY\SYSTEM`

This is an independently concerning finding. SYSTEM should never produce this error under a default Windows configuration. The most likely causes are:

- A Group Policy Object modified the **User Rights Assignment** (`Allow log on locally`, `Log on as a service`) in a way that explicitly enumerates accounts and omitted SYSTEM.
- A security baseline or CIS hardening script was applied that changed the service's logon account or the local security policy.
- The service registry entry (`HKLM\SYSTEM\CurrentControlSet\Services\Spooler`) was manually edited or tampered with, changing the `ObjectName` value from `LocalSystem`.

---

## 5. Ranked Remediation Plan

### Step 1 — Identify and Remove the Corrupt Printer Driver

This resolves the `ERROR_MOD_NOT_FOUND` (7023) and stops the crash loop.

```powershell
# List all installed printer drivers (run as Administrator)
Get-PrinterDriver | Select-Object Name, InfPath, PrinterEnvironment | Format-Table -AutoSize

# Attempt to identify which driver is missing its module
# Check spooler event log for additional detail around 10:01-10:03
Get-WinEvent -LogName System -FilterXPath "*[System[EventID=7023]]" |
    Select-Object TimeCreated, Message | Format-List
```

To remove a suspect driver:

```powershell
# Remove a specific driver by name (replace DriverName with actual name)
Remove-PrinterDriver -Name "DriverName"

# Force-remove if the standard cmdlet fails (requires spooler stopped)
Stop-Service Spooler -Force
rundll32 printui.dll,PrintUIEntry /dd /m "DriverName" /v "Windows x64" /b
```

Alternatively, use Print Management console (`printmanagement.msc`) → Drivers → identify entries with missing files.

**If all drivers look valid,** check the driver store for orphaned entries:

```powershell
# List driver store contents
pnputil /enum-drivers | Select-String "spoo|print" -Context 3
```

---

### Step 2 — Clear the Spooler Queue and Spool Directory

Corrupt spool files can also cause the Spooler to fail on load:

```powershell
Stop-Service Spooler -Force

# Clear the spool directory
Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue

Start-Service Spooler
Get-Service Spooler | Select-Object Status
```

---

### Step 3 — Resolve the SYSTEM Logon Type Restriction

This resolves Event ID 7038.

```powershell
# Verify the service's configured logon account
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler" -Name ObjectName

# Expected value: LocalSystem
# If it shows anything else, reset it:
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler" -Name ObjectName -Value "LocalSystem"
```

Check the local security policy for User Rights Assignment changes:

```
secpol.msc → Local Policies → User Rights Assignment
→ "Log on as a service" — verify NT AUTHORITY\SYSTEM is not explicitly excluded
→ "Deny log on as a service" — verify SYSTEM is not listed here
```

Check for a GPO enforcing this restriction:

```powershell
# Review resultant set of policy for the affected machine
gpresult /H C:\Temp\gpresult.html /F
# Open gpresult.html and review User Rights Assignment section
```

If a GPO is responsible, identify it and assess whether the restriction is intentional. Engage the Group Policy owner before modifying.

---

### Step 4 — Verify Spooler Starts Cleanly and Monitor

```powershell
# Start spooler and check status
Start-Service Spooler
Get-Service Spooler

# Watch for further 7034/7031/7023/7038 events over 5 minutes
Get-WinEvent -LogName System -MaxEvents 30 |
    Where-Object { $_.Id -in @(7034, 7031, 7023, 7038) } |
    Select-Object TimeCreated, Id, Message | Format-List
```

---

### Step 5 — Reinstall Affected Printer Drivers

If Step 1 identifies a corrupt driver that cannot be cleanly removed:

1. Download the latest driver package from the printer manufacturer.
2. Stop the Spooler, manually clear `%SystemRoot%\System32\spool\drivers\x64\` of the affected driver folder, then restart and reinstall via Device Manager or `printui.dll`.

> **[VERIFY AGAINST MICROSOFT DOCS]** — If the Spooler crash loop started after a recent Windows Update (particularly PrintNightmare-related patches), check the Microsoft known issue list for the current OS build (22621.3155) for Print Spooler regressions.

---

## 6. Impact Assessment

| Area | Impact |
|------|--------|
| Print functionality | Complete loss — all print jobs fail while Spooler is down |
| User productivity | Any user or process relying on print on this endpoint is blocked |
| Data integrity | Queued print jobs in spool directory may be lost |
| Security risk | PrintNightmare (CVE-2021-1675/34527) exploits target the Spooler — confirm the crash was not triggered by an exploitation attempt if the 7034 events began suddenly without a prior driver change |
| Service recovery | Automatic recovery exhausted; manual intervention required |

---

## 7. Security Note — PrintNightmare Consideration

If the first crash at 10:01:14 was not preceded by any administrative change to printer drivers, the sudden onset of a Spooler crash loop should raise a question: **was an exploitation attempt made against the Print Spooler?**

Check for the following alongside the 7034 events:

```powershell
# Look for suspicious driver installation events around the same time
Get-WinEvent -LogName System | Where-Object { $_.TimeCreated -gt "2024-03-15 09:50:00" -and $_.TimeCreated -lt "2024-03-15 10:05:00" } |
    Where-Object { $_.Id -in @(7045, 7040, 4688) } |
    Select-Object TimeCreated, Id, Message | Format-List

# Event 7045 = new service installed (used in PrintNightmare to load malicious DLL)
```

If Event ID 7045 appears in the window before the crashes with an unexpected service or driver name, escalate to the security team immediately.

---

## 8. Recommended Actions

| Priority | Action | Owner |
|----------|--------|-------|
| Immediate | Stop/disable Spooler to halt crash loop noise | Helpdesk |
| High | Identify missing driver module via Get-PrinterDriver | Helpdesk / Desktop engineer |
| High | Remove corrupt/orphaned printer driver | Desktop engineer |
| High | Investigate SYSTEM logon restriction — check GPO | Desktop engineer / GPO owner |
| High | Reset Spooler service ObjectName to LocalSystem if changed | Desktop engineer |
| Medium | Clear spool directory and restart Spooler | Helpdesk |
| Medium | Check for Event ID 7045 in the window before crashes | Security analyst |
| Low | Reinstall affected printer driver from vendor source | Desktop engineer |

---

## 9. Preventive Measures

1. **Driver management policy:** Standardise on a vetted set of printer drivers deployed via print server or Intune. Avoid ad-hoc driver installation on endpoints.
2. **Spooler hardening:** Consider running the Print Spooler only on endpoints that actually require printing. On servers, disable if not needed (Microsoft guidance post-PrintNightmare).
3. **Point and Print restrictions:** Enforce `RestrictDriverInstallationToAdministrators` policy to prevent non-admin printer driver installation, which is a common vector for both accidental corruption and exploitation.
4. **GPO review cadence:** Maintain a review schedule for User Rights Assignment GPOs — changes to these settings frequently produce unexpected service logon failures (7038) that are difficult to diagnose without change history.
5. **Alerting:** Configure monitoring to alert on 3 or more 7034 events for the same service within a 5-minute window — this is a reliable indicator of a crash loop requiring intervention.

---

## 10. Sign-off

| Role | Name | Date |
|------|------|------|
| Analyst | *[DWP Analyst]* | 2024-03-15 |
| Desktop Engineering Lead | *[Desktop Lead]* | |
| Security Review | *[Security Team]* | |

---

*Document classification: OFFICIAL. Retain in accordance with DWP records management policy.*
