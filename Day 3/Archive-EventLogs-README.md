# Archive-EventLogs.ps1 — DWP Event Log Archive Utility

## Overview

A **production-ready**, safe-by-default PowerShell 5.1 script that exports
selected Windows Event Log channels to dated `.evtx` archive files and then
clears the live logs. Only logs that contain records older than a configurable
age threshold are processed. Every action is written to a timestamped audit log.

> **Requires:** Windows PowerShell 5.1 · Administrator privileges

---

## How It Works

| Step | Description |
|------|-------------|
| **1. Privilege check** | Aborts immediately if not running as Administrator. |
| **2. Old-record count** | Queries each target log for records older than `OlderThanDays`. Logs with no qualifying records are skipped. |
| **3. Idempotency check** | If a log was already archived today (any run), it is skipped automatically. |
| **4. Export** | Uses `wevtutil epl` to export the full log to a timestamped `.evtx` file. |
| **5. Clear** | Uses `wevtutil cl` to clear the live log. The archive is preserved regardless of whether the clear succeeds. |
| **6. Manifest** | Writes a `manifest.csv` alongside the archive so rollback knows which files to restore. |
| **7. Summary** | Prints a structured summary of every run to the console and the audit log. |

---

## Folder Layout

```
C:\EventLogArchive\                        ← ArchiveRoot (configurable)
│
├── Logs\
│   └── EventLogArchive_20260810_040205.log   ← audit log per run
│
├── 20260810_040205\                           ← one folder per archive run
│   ├── manifest.csv
│   ├── Application.evtx
│   ├── System.evtx
│   └── Security.evtx
│
└── Restored_20260811_090000\                  ← created by -Rollback
    ├── Application.evtx
    └── System.evtx
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-DryRun` | Switch | off | Preview mode — reports old record counts and what would be archived. **No files are created or modified.** |
| `-OlderThanDays` | Int | `3` | Only process logs that contain at least one record older than this many days. Minimum value: 1. |
| `-LogNames` | String\[\] | `Application, System, Security, Setup` | Windows Event Log channel names to target. |
| `-ArchiveRoot` | String | `C:\EventLogArchive` | Root folder for archive output, manifests, and script logs. Created automatically if it does not exist. |
| `-Rollback` | Switch | off | Activates rollback mode. Copies archived `.evtx` files to a `Restored_<timestamp>` folder. Cannot be combined with archive parameters. |
| `-RollbackArchivePath` | String | *(auto-detect)* | Full path to a specific archive run folder to restore from. If omitted, the most recent folder under `ArchiveRoot` is used. |

---

## Usage Examples

### 1 — Preview what would be archived (no changes)
```powershell
.\Archive-EventLogs.ps1 -DryRun
```

### 2 — Archive with the default settings (records older than 3 days)
```powershell
.\Archive-EventLogs.ps1
```

### 3 — Archive records older than 7 days
```powershell
.\Archive-EventLogs.ps1 -OlderThanDays 7
```

### 4 — Target specific log channels only
```powershell
.\Archive-EventLogs.ps1 -LogNames Application,System -OlderThanDays 3
```

### 5 — Use a custom archive root
```powershell
.\Archive-EventLogs.ps1 -ArchiveRoot 'D:\Logs\EventArchive'
```

### 6 — Roll back the most recent archive run
```powershell
.\Archive-EventLogs.ps1 -Rollback
```

### 7 — Roll back a specific archive run
```powershell
.\Archive-EventLogs.ps1 -Rollback -RollbackArchivePath "C:\EventLogArchive\20260810_040205"
```

### 8 — Preview a rollback without restoring anything
```powershell
.\Archive-EventLogs.ps1 -Rollback -DryRun
```

---

## Dry Run Mode

When `-DryRun` is set:

- No `.evtx` files are created.
- No live logs are cleared.
- No directories or manifest files are written.
- The script prints the **count of records that would be deleted** for each qualifying log, prefixed with `[DRY RUN]` in cyan.

Always run with `-DryRun` first to validate scope before executing a live archive.

---

## Rollback

Rollback restores archived event data by copying `.evtx` files from a previous archive run to a new `Restored_<timestamp>` folder under `ArchiveRoot`.

### How to use restored files

1. Open **Windows Event Viewer** (`eventvwr.msc`).
2. Click **Action → Open Saved Log ...** (or **File → Open Saved Log** in older versions).
3. Browse to the restored `.evtx` file (e.g. `C:\EventLogArchive\Restored_20260811_090000\Application.evtx`).
4. The log appears as a saved log in the left panel where you can filter, search, and export records.

> **Note:** Rollback does not re-import events back into the live log channel because doing so would require stopping the Windows Event Log service, which is disruptive. The restored `.evtx` files are fully readable in Event Viewer and queryable with `Get-WinEvent -Path <file>`.

---

## Idempotency

If you run the script multiple times on the same day, logs that were already archived in an earlier run that day are automatically skipped. The check reads the `manifest.csv` of every archive folder whose name begins with today's date (`yyyyMMdd`).

This makes the script safe to schedule via Task Scheduler without risk of double-archiving.

---

## Audit Logging

Every action — including skips, errors, and dry-run outputs — is written to a timestamped `.log` file in `<ArchiveRoot>\Logs\`. Log entries follow this format:

```
[2026-08-10 04:02:05] [INFO]  Exporting 'Application' to 'C:\EventLogArchive\20260810_040205\Application.evtx' ...
[2026-08-10 04:02:07] [INFO]  Export of 'Application' completed successfully.
[2026-08-10 04:02:07] [WARN]  'Security' was already archived today (20260810). Skipping (idempotent).
[2026-08-10 04:02:08] [ERROR] Export failed for 'Setup': Access denied.
```

Log levels: `INFO` · `WARN` · `ERROR` · `DRY`

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All target logs processed successfully (or nothing to do). |
| `1` | One or more logs failed to archive or roll back. |

Exit code `1` allows Task Scheduler, monitoring tools, or CI pipelines to detect partial failures.

---

## Scheduling with Task Scheduler

To run this script automatically each night at 2 AM:

1. Open **Task Scheduler** and create a new basic task.
2. Set the trigger to **Daily** at `02:00`.
3. Set the action to **Start a program**:
   - **Program:** `powershell.exe`
   - **Arguments:** `-NonInteractive -ExecutionPolicy RemoteSigned -File "C:\Scripts\Archive-EventLogs.ps1" -OlderThanDays 3`
4. Under **General**, enable **Run with highest privileges**.
5. Under **General**, set **Run whether user is logged on or not**.

---

## Security Notes

- The script requires **Administrator** privileges and enforces this at startup.
- `wevtutil` operates only on channels listed in the `-LogNames` parameter; no other system state is modified.
- No network access is performed; all output is written locally under `ArchiveRoot`.
- The script does **not** suppress or bypass execution policy — pass `-ExecutionPolicy RemoteSigned` explicitly when scheduling.
