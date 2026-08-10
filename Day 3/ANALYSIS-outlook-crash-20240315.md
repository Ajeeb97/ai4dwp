# Application Crash Analysis — Microsoft Outlook
## INC-2024-0315-APP001 | OUTLOOK.EXE | Event ID 1000 / 1001 / 1026

---

## 1. Incident Summary

| Field | Detail |
|-------|--------|
| **Incident ID** | INC-2024-0315-APP001 |
| **Date / Time** | 2024-03-15, 09:13 – 09:18 (local time) |
| **Affected Application** | Microsoft Outlook (OUTLOOK.EXE) v16.0.17126.20132 |
| **Affected Process ID** | 0x1f4c |
| **Crash Count** | 2 confirmed crashes within 4 minutes |
| **Faulting Module** | KERNELBASE.dll v10.0.22621.3155 |
| **Exception Code** | 0xc0000005 (STATUS_ACCESS_VIOLATION) |
| **Report ID** | a3c2f1d4-89bb-4e21-91d7-f2c3a1b09e44 |
| **Severity** | Medium — application unavailable, user unable to access email |

---

## 2. Event Log Entries — Reference

### Event ID 1000 — Application Error (Source: Application Error)

Generated whenever a Windows application crashes and the operating system's fault handler captures the failure. Records the faulting application, the module that was executing at the point of crash, the exception code, the memory offset of the instruction that faulted, and the process ID. Two instances of this event were recorded:

| Field | Crash 1 (09:14:22) | Crash 2 (09:17:45) |
|-------|-------------------|-------------------|
| Application | OUTLOOK.EXE | OUTLOOK.EXE |
| App version | 16.0.17126.20132 | 16.0.17126.20132 |
| Faulting module | KERNELBASE.dll | KERNELBASE.dll |
| Module version | 10.0.22621.3155 | 10.0.22621.3155 |
| Exception code | 0xc0000005 | 0xc0000005 |
| Fault offset | 0x000000000003a4b2 | 0x000000000003a4b2 |

**Critical observation:** The fault offset is **identical** in both crashes. This is not a random or intermittent failure — the application is hitting precisely the same instruction in KERNELBASE.dll on every run. This is a deterministic, reproducible crash.

---

### Event ID 1001 — Windows Error Reporting (Source: Windows Error Reporting)

Generated after a crash is captured by the Windows Error Reporting (WER) service. WER categorises the crash into a "fault bucket" for telemetry grouping and optionally submits a report to Microsoft. Key fields:

- **Fault bucket 1847362910, type 4** — Type 4 denotes an `APPCRASH` bucket (unhandled exception in a user-mode application).
- **Response: Not available** — No automated fix or Known Issue Rollback (KIR) was available from Microsoft at the time of the crash. This means the specific crash signature is not yet matched to a published workaround in WER's response database.
- **Cab Id: 0** — No crash dump (cabinet file) was captured or uploaded. This limits post-mortem debugging. If a full memory dump is needed, WER local dump collection would need to be enabled.

---

### Event ID 1026 — .NET Runtime (Source: .NET Runtime)

Generated when a .NET managed process terminates due to an unhandled exception that bubbled up through the runtime. Despite Outlook being a primarily native (Win32/COM) application, it hosts managed (.NET) components and add-ins via the .NET 4.0 runtime.

- **Framework Version: v4.0.30319** — Outlook's managed hosting layer was using .NET Framework 4.x.
- **Exception: System.AccessViolationException** — The .NET runtime's translation of the native `0xc0000005 STATUS_ACCESS_VIOLATION`. This means a managed component (add-in, COM interop wrapper, or managed Office extension) attempted to read from or write to a memory address that it did not own or that was null/invalid.

This event **confirms and corroborates** the native exception code seen in Event ID 1000.

---

## 3. Exception Code Analysis

### 0xc0000005 — STATUS_ACCESS_VIOLATION

This is one of the most common and well-understood Windows exception codes. It means the faulting thread attempted to **read from or write to a virtual memory address that the process does not have permission to access**, or that does not map to physical memory.

Common root causes in an Office/Outlook context:

| Cause | Likelihood |
|-------|-----------|
| Faulty or incompatible COM/VSTO add-in dereferencing a null or stale pointer | High |
| Corrupt Outlook profile or OST/PST data file causing bad object reference | High |
| Corrupt Office installation (missing or mismatched DLL) | Medium |
| Incompatible third-party plugin (antivirus email scanner, CRM integration) | Medium |
| Corrupted Windows system file (KERNELBASE.dll itself) | Low — KERNELBASE.dll is more commonly the exception catcher than the root cause |
| Hardware memory fault | Low — identical fault offset across two separate process instances makes this unlikely |

### Why KERNELBASE.dll?

KERNELBASE.dll is the low-level Windows API implementation library (`kernel32.dll` forwards many calls to it). When it appears as the *faulting module*, it typically means KERNELBASE.dll was the module **executing when the exception was raised** — for example, because a called API function detected the access violation — not that KERNELBASE.dll itself is corrupt. The true origin of the corruption is almost always in the calling code (an add-in, a bad pointer passed from Outlook's own code, or a managed interop layer).

The fault offset `0x000000000003a4b2` points to a specific instruction within KERNELBASE.dll. Resolving this to a function name would require a kernel debugger and symbol files, but the repeatable nature of the offset strongly suggests the same code path — and therefore the same upstream caller — is responsible every time.

---

## 4. Sequence of Events — Narrative

**09:13:44** — Outlook launches (Process ID 0x1f4c). The application begins initialising — loading the user profile, connecting to Exchange/OST, and initialising COM add-ins.

**09:14:22** — 38 seconds after launch, Outlook crashes. An access violation (0xc0000005) is raised at KERNELBASE.dll offset 0x000000000003a4b2. The process terminates. Windows logs Event ID 1000.

**09:17:45** — Outlook is re-launched (manually or automatically). It crashes again, at the **identical fault offset**, within a similar timeframe. This rules out a transient condition. Windows logs a second Event ID 1000.

**09:18:01** — Windows Error Reporting buckets the crash as APPCRASH type 4. No automated remedy is available from Microsoft's response servers. No crash dump is collected.

**09:18:05** — The .NET runtime logs the crash as an unhandled `System.AccessViolationException`, confirming a managed component was involved in the failure chain.

---

## 5. Root Cause Assessment

**Most likely root cause: A COM or VSTO add-in is triggering a memory access violation during Outlook's initialisation sequence.**

Reasoning:
1. Outlook crashes during startup (38 seconds in), which is when add-ins are loaded and initialised — a known high-risk window for add-in-induced crashes.
2. The identical fault offset across two separate process instances confirms a deterministic code path, not a one-off memory state issue.
3. Event ID 1026 explicitly identifies a .NET managed exception (`System.AccessViolationException`), pointing to managed code (VSTO add-in, COM interop, or third-party managed extension) as the origin.
4. KERNELBASE.dll has no known crash at this offset for this build version without an upstream caller providing a bad memory reference.
5. The WER response "Not available" means this is not a known patched Office bug — the issue is likely environmental (local add-in or configuration) rather than a global Office defect.

**Alternative cause:** Corrupt OST file or Outlook profile. If an add-in attempts to access the profile or data store during init and the data is corrupt, a bad pointer could result in the same pattern.

---

## 6. Ranked Remediation Plan

### Step 1 — Launch Outlook in Safe Mode (immediate diagnostic)

Safe mode disables all COM and VSTO add-ins. If Outlook loads successfully, an add-in is confirmed as the cause.

```
Win + R → outlook.exe /safe
```

If Outlook opens in safe mode: proceed to Step 2.
If Outlook crashes even in safe mode: proceed to Step 4 (profile/OST).

---

### Step 2 — Identify and Disable Faulty Add-in

```
File → Options → Add-ins → COM Add-ins → Go
```

Disable all add-ins. Re-enable them one at a time, restarting Outlook after each, until the crash recurs. The last add-in enabled before the crash is the faulting component.

Common suspects in enterprise environments:
- Antivirus email scanning plugins (Symantec, McAfee, Defender ATP add-in)
- CRM integrations (Salesforce for Outlook, Dynamics 365)
- Adobe Acrobat PDF add-in
- Teams Meeting Add-in (if outdated relative to Office version)

---

### Step 3 — Update or Remove the Faulting Add-in

If identified:
- Check the add-in vendor's release notes for known compatibility issues with Office 16.0.17126.x
- Update the add-in to the latest version
- If no update is available, remove the add-in and notify the relevant business team

---

### Step 4 — Check and Rebuild the Outlook Profile / OST

If safe mode also crashes, or as a parallel action:

```powershell
# Locate OST file path (run as the affected user)
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Outlook" -Filter "*.ost" | Select-Object Name, Length, LastWriteTime
```

- In Outlook: File → Account Settings → Account Settings → Data Files — note the OST path
- Close Outlook, rename the OST file (e.g., append `.old`)
- Re-open Outlook — it will rebuild the OST from Exchange. A large mailbox may take time to re-sync.
- If this resolves the crash, the original OST was corrupt.

To create a new Outlook profile:
```
Control Panel → Mail → Show Profiles → Add
```

---

### Step 5 — Run Office Online Repair

If Steps 1–4 do not resolve the issue, the Office installation itself may be corrupt:

```
Settings → Apps → Microsoft 365 / Office → Modify → Online Repair
```

Online Repair re-downloads Office components from Microsoft's servers. Requires internet access and ~30 minutes. Prefer over Quick Repair for persistent crashes involving KERNELBASE.dll.

---

### Step 6 — Check Windows System File Integrity

KERNELBASE.dll involvement, while likely as an exception catcher, warrants a system file check:

```powershell
# Verify system file integrity
sfc /scannow

# Verify and restore Windows image health
DISM /Online /Cleanup-Image /RestoreHealth
```

---

### Step 7 — Enable Crash Dump Collection (if issue persists)

Since WER captured no dump (Cab Id: 0), enable local crash dump collection to allow deeper analysis:

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\OUTLOOK.EXE]
"DumpFolder"="C:\\CrashDumps"
"DumpCount"=dword:00000005
"DumpType"=dword:00000002
```

Reproduce the crash, then submit the `.dmp` file to Microsoft Support or analyse with WinDbg.

---

## 7. Impact Assessment

| Area | Impact |
|------|--------|
| User productivity | User unable to access email for the duration |
| Data integrity | No data loss expected — crash occurred at startup, no write operations in progress |
| Service impact | None — Exchange/server-side unaffected |
| Security risk | None identified |
| Repeat risk | High — deterministic crash will recur on every Outlook launch until resolved |

---

## 8. Recommended Actions

| Priority | Action | Owner |
|----------|--------|-------|
| Immediate | Launch Outlook /safe to confirm add-in cause | Helpdesk / End User |
| High | Identify and disable faulting add-in | Helpdesk |
| High | Update or remove faulting add-in | Helpdesk / App owner |
| Medium | Rebuild OST/profile if safe mode also crashes | Helpdesk |
| Medium | Run Office Online Repair if above fails | Helpdesk |
| Low | Enable WER local dump if issue persists beyond above steps | Senior analyst |
| Low | Run SFC and DISM as precaution | Helpdesk |

---

## 9. Preventive Measures

1. **Add-in governance:** Maintain an approved list of COM/VSTO add-ins tested against the current Office build. Evaluate add-in compatibility before Office update deployment.
2. **Office update ring:** Ensure Office Click-to-Run is on a managed update channel (Monthly Enterprise or Semi-Annual Enterprise) so version changes are controlled and tested before rollout.
3. **Crash monitoring:** Configure SIEM or endpoint management (Intune/MECM) to alert on repeated Event ID 1000 for `OUTLOOK.EXE` within a short window — two crashes in under 5 minutes should auto-raise a ticket.
4. **OST size limits:** Enforce OST/PST size limits via Group Policy to reduce the risk of data file corruption in large mailboxes.
5. **WER dump policy:** Consider enabling local WER dump collection organisation-wide for designated critical applications (Outlook, Teams) to improve future crash diagnostics without manual intervention.

---

## 10. Sign-off

| Role | Name | Date |
|------|------|------|
| Analyst | *[DWP Analyst]* | 2024-03-15 |
| Helpdesk Lead | *[Helpdesk Lead]* | |
| App Owner (M365) | *[M365 Team]* | |

---

*Document classification: OFFICIAL. Retain in accordance with DWP records management policy.*
